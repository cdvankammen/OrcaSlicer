# OrcaSlicer Codebase Exploration Summary

**Date:** 2026-02-13
**Purpose:** Document existing patterns, reusable code, and architectural conventions before implementing multi-extruder features

---

## Table of Contents

1. [Multi-Material Flushing Implementation](#1-multi-material-flushing-implementation)
2. [Configuration System](#2-configuration-system)
3. [GUI Patterns](#3-gui-patterns)
4. [3MF Serialization](#4-3mf-serialization)
5. [Code Reuse Opportunities](#5-code-reuse-opportunities)
6. [Coding Standards Observed](#6-coding-standards-observed)

---

## 1. Multi-Material Flushing Implementation

### 1.1 WipeTower (Prime Tower)

**Files:**
- `src/libslic3r/GCode/WipeTower.hpp` - BBL/Bambu printer wipe tower
- `src/libslic3r/GCode/WipeTower.cpp`
- `src/libslic3r/GCode/WipeTower2.hpp` - ORCA implementation for MMU/toolchanger
- `src/libslic3r/GCode/WipeTower2.cpp`

**Key Data Structure - ToolChangeResult:**
```cpp
struct ToolChangeResult {
    float print_z;              // Height of tool change
    float layer_height;         // Layer height
    std::string gcode;          // Generated G-code
    std::vector<Extrusion> extrusions;  // Preview paths
    Vec2f start_pos, end_pos;   // Position before/after
    float elapsed_time;         // Time spent
    float purge_volume;         // Amount purged
    unsigned int initial_tool, new_tool;  // Extruder transition
};
```

**Key Methods:**
- `plan_toolchange(z, layer_height, old_tool, new_tool, wipe_volume, prime_volume)` - Lines 188
  - Called from `Print::process_layers()` for each tool change
  - Stores tool change info in internal `m_plan` vector
  - Called AFTER `mark_wiping_extrusions()` so remaining purge volume is known

- `generate() / generate_new()` - Lines 191
  - Iterates through m_plan and generates actual ToolChangeResult objects
  - Returns vector of vectors: outer = layers, inner = tool changes per layer

**Reusable Pattern:** When adding filament filtering, modify the planning phase to filter which filaments participate in tower generation.

---

### 1.2 WipingExtrusions (Object/Support/Infill Flushing)

**File:** `src/libslic3r/GCode/ToolOrdering.cpp` (Lines 1564-1840)

**Key Data Structures:**
```cpp
class WipingExtrusions {
    // Maps (extrusion, object) to per-copy extruder overrides
    std::map<std::tuple<const ExtrusionEntity*, const PrintObject*>, ExtruderPerCopy> entity_map;

    // Override extruder for support material
    std::map<const PrintObject*, int> support_map;
    std::map<const PrintObject*, int> support_intf_map;
};
```

**Core Method - mark_wiping_extrusions() (Lines 1599-1736):**

Flow:
1. **Early exits** (1604-1609):
   - Skip if nothing overridable or volume is 0
   - Skip if either extruder uses soluble filament
   - Skip if either extruder is support filament

2. **Object sorting** (1611-1621):
   - Sort objects to prioritize dedicated flushing objects first
   - Uses `flush_into_objects` config to identify dedicated objects

3. **Two-pass algorithm** (1628-1732):
   - First pass: Mark perimeters or infills (depending on `is_infill_first`)
   - Second pass: Mark the other type
   - Allows proper ordering when infill_first differs from wiping happens

4. **Filtering criteria** (1651-1690):
   - Check `flush_into_infill`, `flush_into_objects`, `flush_into_support` flags
   - Use `is_overriddable()` to validate extrusions can be recolored
   - Skip already overridden entities

5. **Support flushing** (1694-1730):
   - Check if support/interface can be overridden (when filament_id == 0)
   - Mark support extrusions with new extruder
   - Decrease remaining volume_to_wipe

**Returns:** Remaining volume that must be purged on wipe tower

**Reusable Functions:**
- `is_overriddable(eec, print_config, object, region)` (Lines 1564-1576)
  - Determines if extrusion can be recolored/flushed into
  - Returns false if extruder uses soluble filament
  - Returns true if `flush_into_objects` enabled
  - For `flush_into_infill`, only allows internal infill (erInternalInfill role)

- `is_support_overriddable(role, object)` (Lines 1579-1595)
  - Checks if support can be recolored
  - Returns false if `flush_into_support` disabled
  - For erMixed: allows if support_filament==0 OR support_interface_filament==0
  - For erSupportMaterial: allows if support_filament==0
  - For erSupportMaterialInterface: allows if support_interface_filament==0

**Integration Point for New Features:**
Add filament filtering logic here - before marking extrusions, check if the new_extruder filament is allowed to flush into this entity type.

---

### 1.3 ToolOrdering (Tool Change Sequencing)

**File:** `src/libslic3r/GCode/ToolOrdering.cpp` (Lines 1-1600)

**Key Data Structure - LayerTools:**
```cpp
class LayerTools {
    coordf_t print_z = 0.;
    std::vector<unsigned int> extruders;  // 0-based, minimized order
    bool has_wipe_tower = false;
    WipingExtrusions& wiping_extrusions();
};
```

**Key Class - ToolOrdering:**
```cpp
class ToolOrdering {
    std::vector<LayerTools> m_layer_tools;
    unsigned int m_first_printing_extruder;
    unsigned int m_last_printing_extruder;
    std::vector<unsigned int> m_all_printing_extruders;
};
```

**Key Methods:**
- `sort_and_build_data()` - Builds layer_tools sequence
- `has_wipe_tower()` - Returns true if wipe tower should be used
- `tools_for_layer(print_z)` - Find LayerTools closest to given z
- `all_extruders()` - Returns all printing extruders in prime sequence

---

### 1.4 Integration Flow (Print Slicing Process)

**File:** `src/libslic3r/Print.cpp` (Lines 3098-3260)

**High-Level Flow:**

```
1. Initialize ToolOrdering (Line 3099)
   └─ ToolOrdering(*this, -1, bUseWipeTower2)

2. Build Flush Matrices (Lines 3165-3174)
   └─ get_flush_volumes_matrix()
   └─ Creates [nozzle_id][from_filament][to_filament] lookup

3. Plan Tool Changes Layer-by-Layer (Lines 3183-3224)
   For each layer_tools:
     For each filament_id:
       ├─ Calculate purge volume from matrix
       ├─ mark_wiping_extrusions(*this, old, new, volume_to_purge)
       │   └─ Returns remaining volume
       └─ wipe_tower.plan_toolchange(z, layer_height, old, new, remaining)

4. Generate Wipe Tower (Lines 3236-3240)
   └─ wipe_tower.generate_new(m_wipe_tower_data.tool_changes)

5. Final Purge (Lines 3250-3260)
   └─ wipe_tower.tool_change(-1)
```

**Key Configuration Parameters:**
- `flush_into_infill` (PrintConfig.cpp:6471-6478) - Bool, default false
- `flush_into_support` (PrintConfig.cpp:6480-6486) - Bool, default true
- `flush_into_objects` (PrintConfig.cpp:6488-6494) - Bool, default false
- `support_filament` / `support_interface_filament` - When 0, allows flushing

---

### 1.5 Reusable Code for Feature Implementation

**For Feature #3 & #4 (Material-Specific Flushing):**

1. **Add config options** following pattern in `PrintConfig.cpp:6471-6494`:
   ```cpp
   ConfigOptionInts wipe_tower_filaments;
   ConfigOptionInts support_flush_filaments;
   ConfigOptionInts infill_flush_filaments;
   ```

2. **Modify `mark_wiping_extrusions()`** to check arrays before marking:
   ```cpp
   // Before line 1694 (support marking):
   if (!support_flush_filaments.empty() &&
       std::find(support_flush_filaments.begin(),
                 support_flush_filaments.end(),
                 new_extruder) == support_flush_filaments.end()) {
       continue;  // Skip this support, filament not allowed
   }
   ```

3. **Modify `plan_toolchange()`** to skip tower for excluded filaments:
   ```cpp
   // In WipeTower.cpp before adding to m_plan:
   if (!wipe_tower_filaments.empty() &&
       (std::find(..., new_tool) == end || std::find(..., old_tool) == end)) {
       return;  // Don't add this tool change to tower
   }
   ```

---

## 2. Configuration System

### 2.1 ConfigOption Type System

**File:** `src/libslic3r/Config.hpp` (Lines 157-196)

**Type Hierarchy:**
```
ConfigOption (base interface)
├── ConfigOptionSingle<T>
│   ├── ConfigOptionFloat
│   ├── ConfigOptionInt
│   ├── ConfigOptionString
│   ├── ConfigOptionBool
│   └── ConfigOptionEnum<T>
└── ConfigOptionVector<T>
    ├── ConfigOptionFloats
    ├── ConfigOptionInts       ← WE NEED THIS
    ├── ConfigOptionStrings
    ├── ConfigOptionBools
    └── ConfigOptionPercents
```

**ConfigOptionInts Definition** (Config.hpp:977-1068):
```cpp
template<bool NULLABLE>
class ConfigOptionIntsTempl : public ConfigOptionVector<int> {
    // Deserialize from comma-separated string
    // Support nullable variants with optional values
};
using ConfigOptionInts = ConfigOptionIntsTempl<false>;
```

**Usage Pattern:**
```cpp
// Define in PrintConfig.hpp:
ConfigOptionInts wipe_tower_filaments;

// Initialize in PrintConfig.cpp:
def = this->add("wipe_tower_filaments", coInts);
def->label = L("Prime tower filaments");
def->tooltip = L("Select which filaments use the prime tower");
def->mode = comAdvanced;
def->default_value = new ConfigOptionInts();  // Empty = all
```

---

### 2.2 Config Organization

**File:** `src/libslic3r/PrintConfig.hpp` (Lines 882-1579)

**Hierarchy:**
```
FullPrintConfig (Line 1576-1579)
├── PrintObjectConfig (Line 882-1033)  ← Per-object overrides
├── PrintRegionConfig (Line 1035-1234) ← Per-material/region
└── PrintConfig (Line 1402-1576)       ← Global print settings
```

**PrintObjectConfig Examples:**
- `ConfigOptionFloat layer_height` - Object-specific layer height
- `ConfigOptionInt support_filament` - Which extruder for supports
- `ConfigOptionBool enable_support` - Support enable/disable

**PrintConfig Examples:**
- `ConfigOptionInts nozzle_temperature` - Per-filament temps
- `ConfigOptionFloats nozzle_diameter` - Per-extruder
- `ConfigOptionBool enable_prime_tower` - Wipe tower enable

---

### 2.3 Static vs Dynamic Config

**DynamicPrintConfig** (PrintConfig.hpp:575-647):
- Stores options in `std::map<string, ConfigOptionPtr>`
- Used at GUI level and for per-object overrides
- Allows arbitrary option combinations
- Methods: `set_deserialize()`, `apply()`, `opt_serialize()`

**StaticPrintConfig** (PrintConfig.hpp:660-748):
- Statically defined options at compile-time
- Uses static cache with offset maps (pointer-based access)
- Much faster than dynamic config (no map lookups)
- Used during slicing/G-code generation for performance

---

### 2.4 Config Propagation & Re-Slicing

**File:** `src/libslic3r/Print.cpp` (Lines 94-245)

**Print::invalidate_state_by_config_options():**
- Determines which slicing steps need re-execution based on changed config keys
- Categorizes config options into steps:
  - GCode steps: temperature, fan speed (G-code only, no re-slice)
  - Perimeter steps: line width, wall loops
  - Fill steps: infill pattern, density
  - Support steps: support angle, type

**Reusable Pattern for New Features:**
```cpp
// In Print.cpp invalidate_state_by_config_options():
if (opt_key == "wipe_tower_filaments" ||
    opt_key == "support_flush_filaments" ||
    opt_key == "infill_flush_filaments") {
    steps.emplace_back(psWipeTower);  // Only regenerate wipe tower
}
```

---

### 2.5 Per-Object Config Implementation

**File:** `src/libslic3r/Model.hpp` (Lines 354-435)

**ModelObject Structure:**
```cpp
class ModelObject {
    ModelConfigObject config;  // Line 368 - Per-object config overrides
    t_layer_config_ranges layer_config_ranges;  // Line 370 - Z-range configs
};
```

**ModelConfigObject** (Model.hpp:72-102):
- Wraps `DynamicPrintConfig` internally
- Provides thread-safe getter/setter interface
- Key methods:
  ```cpp
  void assign_config(const DynamicPrintConfig &rhs)
  void apply(const ConfigBase &other, bool ignore_nonexistent = false)
  const ConfigOption* option(const t_config_option_key &opt_key) const
  ```

**Config Override Merging Pattern** (Model.hpp:407-412):
```cpp
template<typename T> const T* get_config_value(
    const DynamicPrintConfig& global_config,
    const std::string& config_option)
{
    if (config.has(config_option))
        return static_cast<const T*>(config.option(config_option));  // Override
    else
        return global_config.option<T>(config_option);  // Global fallback
}
```

**Reusable for Feature #3 (Per-Object Flush Settings):**
Add `flush_into_this_object_filaments` to PrintObjectConfig, then use same merging pattern.

---

### 2.6 Macro-Based Config Definition

**File:** `src/libslic3r/PrintConfig.hpp` (Lines 750-875)

**PRINT_CONFIG_CLASS_DEFINE Macro:**
```cpp
PRINT_CONFIG_CLASS_DEFINE(
    PrintObjectConfig,
    ((ConfigOptionFloat, brim_object_gap))
    ((ConfigOptionBool, brim_use_efc_outline))
    ((ConfigOptionInts, flush_into_this_object_filaments))  ← Add new options here
)
```

**Expands to:**
```cpp
class PrintObjectConfig : public StaticPrintConfig {
    STATIC_PRINT_CONFIG_CACHE(PrintObjectConfig)
public:
    ConfigOptionFloat brim_object_gap;
    ConfigOptionBool brim_use_efc_outline;
    ConfigOptionInts flush_into_this_object_filaments;  // New field

    size_t hash() const throw() { ... }
    bool operator==(const PrintObjectConfig &rhs) const throw() { ... }

protected:
    void initialize(StaticCacheBase &cache, const char *base_ptr) {
        cache.opt_add("brim_object_gap", base_ptr, this->brim_object_gap);
        cache.opt_add("flush_into_this_object_filaments", base_ptr,
                      this->flush_into_this_object_filaments);
    }
};
```

---

## 3. GUI Patterns

### 3.1 Tab Settings Widget Creation

**File:** `src/slic3r/GUI/Tab.cpp` (Lines 3800-5400)

**Basic Pattern:**
```cpp
void TabFilament::build()
{
    // 1. Create page with icon
    auto page = add_options_page(L("Filament"), "custom-gcode_filament");

    // 2. Create option group (logical section)
    auto optgroup = page->new_optgroup(L("Basic information"), L"param_information");

    // 3. Append simple options
    optgroup->append_single_option_line("filament_type", "material_basic_information#type");
    optgroup->append_single_option_line("filament_vendor", "material_basic_information#vendor");

    // 4. Multi-option lines (horizontal grouping)
    Line line = { L("Temperature range"), L("Tooltip text") };
    line.append_option(optgroup->get_option("nozzle_temperature_range_low"));
    line.append_option(optgroup->get_option("nozzle_temperature_range_high"));
    optgroup->append_line(line);

    // 5. Bind change callbacks
    optgroup->m_on_change = [this, optgroup](t_config_option_key opt_key, boost::any value) {
        update_dirty();
        on_value_change(opt_key, value);
    };
}
```

**For Feature #3/#4 Implementation:**
```cpp
// In TabPrint::build() - Multi-material section:
auto optgroup = page->new_optgroup(L("Multi-material"));

// Add wipe tower filament selection
optgroup->append_single_option_line("wipe_tower_filaments",
                                   "multi_material#wipe-tower-filaments");

// Add support flush filament selection
optgroup->append_single_option_line("support_flush_filaments",
                                   "multi_material#support-flush-filaments");

// Add infill flush filament selection
optgroup->append_single_option_line("infill_flush_filaments",
                                   "multi_material#infill-flush-filaments");
```

---

### 3.2 Per-Extruder Option Pattern

**File:** `src/slic3r/GUI/Tab.cpp` (Lines 4914-5036)

**Pattern:**
```cpp
// Create option for specific extruder index
for (size_t extruder_idx = 0; extruder_idx < num_extruders; ++extruder_idx) {
    optgroup->append_single_option_line("nozzle_diameter",
                                       "printer_extruder_basic_information#nozzle-diameter",
                                       extruder_idx);  // ← Index parameter
}
```

---

### 3.3 Conditional Visibility Pattern

**File:** `src/slic3r/GUI/Tab.cpp` (Lines 1414-1423, 5170-5380)

**Toggle Functions:**
```cpp
void Tab::toggle_option(const std::string& opt_key, bool toggle, int opt_index = -1)
{
    Field* field = m_active_page->get_field(opt_key, opt_index);
    if (field)
        field->toggle(toggle);
}

void Tab::toggle_line(const std::string &opt_key, bool toggle, int opt_index)
{
    Line *line = m_active_page->get_line(opt_key, opt_index);
    if (line)
        line->toggle_visible = toggle;
}
```

**Usage in toggle_options() (Line 5170):**
```cpp
void TabPrinter::toggle_options()
{
    bool is_multi_material = m_extruders_count > 1;

    toggle_option("wipe_tower_filaments", is_multi_material);
    toggle_option("support_flush_filaments", is_multi_material);
    toggle_option("infill_flush_filaments", is_multi_material);
}
```

**Reusable for Features #3/#4:**
Show filament selection options only when multi-material is enabled.

---

### 3.4 Per-Object Settings UI

**File:** `src/slic3r/GUI/GUI_ObjectSettings.cpp` (Lines 84-299)

**Pattern:**
```cpp
bool ObjectSettings::update_settings_list()
{
    // Get selected items from object list
    wxDataViewItemArray items;
    objects_ctrl->GetSelections(items);

    // Collect configs from selection
    std::map<ObjectBase *, ModelConfig*> object_configs;
    for (auto item : items) {
        auto type = objects_model->GetItemType(item);

        if (type == itObject) {
            ModelObject* obj = objects_model->GetModelObject(item);
            object_configs[obj] = &obj->config;
        }
        else if (type == itVolume) {
            ModelVolume* vol = objects_model->GetModelVolume(item);
            object_configs[vol] = &vol->config;
        }
    }

    // Update settings panel with configs
    auto tab_object = dynamic_cast<TabPrintModel*>(wxGetApp().get_model_tab());
    tab_object->set_model_config(object_configs);
}
```

**OLD PATTERN (Lines 84-186) - Direct Option Addition:**
```cpp
// Create option groups by category
SettingsFactory::Bundle cat_options = SettingsFactory::get_bundle(&config->get(), is_object_settings);

for (auto& cat : cat_options)
{
    auto optgroup = std::make_shared<ConfigOptionsGroup>(m_og->ctrl_parent(),
                                                         _(cat.first), config);

    // Bind change callback
    optgroup->m_on_change = [this, config](const t_config_option_key& opt_id,
                                          const boost::any& value) {
        this->update_config_values(config);
        wxGetApp().obj_list()->changed_object();
    };

    // Add all options for this category
    for (auto& opt : cat.second) {
        Option option = optgroup->get_option(opt);
        option.opt.width = 12;
        optgroup->append_single_option_line(option);
    }

    m_settings_list_sizer->Add(optgroup->sizer, 0, wxEXPAND | wxALL, 0);
    m_og_settings.push_back(optgroup);
}
```

**Reusable for Feature #3 (Per-Object Flush Settings):**
Add "Flush object" category with `flush_into_this_object_filaments` option.

---

### 3.5 CheckBox and Choice Field Implementations

**CheckBox Field** (`src/slic3r/GUI/Field.cpp` - Lines 964-1052):
```cpp
void CheckBox::BUILD() {
    // Uses custom ::CheckBox widget from Widgets/CheckBox.hpp
    static Builder<::CheckBox> builder;
}

void CheckBox::set_value(const bool value, bool change_event) {
    dynamic_cast<::CheckBox *>(window)->SetValue(value);
}

boost::any& CheckBox::get_value() {
    bool value = dynamic_cast<::CheckBox*>(window)->GetValue();
    return m_value = value;
}
```

**Choice Field** (`src/slic3r/GUI/Field.cpp` - Lines 1233-1691):
```cpp
void Choice::BUILD() {
    // Create choice/combo control based on option type
}

void Choice::set_values(const wxArrayString &values) {
    // Update list of available choices
}
```

---

### 3.6 Multi-Selection Widget (CheckListBox)

**File:** `src/slic3r/GUI/wxExtensions.hpp` (Lines 95-128)

**CheckListBoxComboPopup:**
```cpp
class wxCheckListBoxComboPopup : public wxCheckListBox, public wxComboPopup
{
    wxString m_text;

public:
    virtual bool Create(wxWindow* parent);
    virtual wxString GetStringValue() const;
    void OnCheckListBox(wxCommandEvent& evt);
    void OnListBoxSelection(wxCommandEvent& evt);
};
```

**Reusable for Feature #3/#4:**
Use this widget pattern for multi-filament selection checkboxes.

---

### 3.7 Line Structure (Multi-Widget Grouping)

**File:** `src/slic3r/GUI/OptionsGroup.hpp` (Lines 51-93)

**Line Class:**
```cpp
class Line {
    wxString label;
    wxString label_tooltip;
    bool toggle_visible{true};

    void append_option(const Option& option) {
        m_options.push_back(option);
    }

    void append_widget(const widget_t widget) {
        m_extra_widgets.push_back(widget);
    }
};
```

**Usage:**
```cpp
Line line = { L("Label"), L("Tooltip") };
line.append_option(optgroup->get_option("option1"));
line.append_option(optgroup->get_option("option2"));
optgroup->append_line(line);
```

---

## 4. 3MF Serialization

### 4.1 XML Structure

**Files:**
- `src/libslic3r/Format/bbs_3mf.cpp` (Lines 103-8000+)
- `src/libslic3r/Format/bbs_3mf.hpp` (Lines 52-119)

**3MF Archive Structure:**
```
project.3mf (ZIP archive)
├── 3D/
│   └── 3dmodel.model (XML - object geometry)
├── Metadata/
│   ├── model_settings.config (XML - per-object/volume configs)
│   ├── slice_info.config (XML - per-plate slicing metadata)
│   └── project_settings.config (JSON - global project config)
├── Thumbnails/
│   └── thumbnail.png
└── [Content_Types].xml
```

**Config XML Structure:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<config>
  <object id="1">
    <metadata key="name" value="..."/>
    <metadata key="config_option_key" value="serialized_value"/>

    <part id="..." subtype="...">
      <metadata key="name" value="..."/>
      <metadata key="config_option_key" value="serialized_value"/>
    </part>
  </object>

  <plate>
    <metadata key="plate_id" value="1"/>
    <metadata key="plate_name" value="..."/>
    <metadata key="config_option_key" value="serialized_value"/>
  </plate>
</config>
```

---

### 4.2 Version Handling & Backward Compatibility

**Version Constants** (Lines 103-122):
```cpp
const unsigned int VERSION_BBS_3MF = 1;
const unsigned int VERSION_BBS_3MF_COMPATIBLE = 2;
const char* BBS_3MF_VERSION = "BambuStudio:3mfVersion";
```

**Backward Compatibility Pattern:**
- Missing fields are silently ignored (graceful degradation)
- Unknown metadata keys are skipped (no error)
- Optional fields only written if data exists
- Version checking currently disabled (all versions accepted)

---

### 4.3 Per-Object/Volume Config Serialization

**Export** (Lines 7558-7658):
```cpp
// Per-object config
for (const auto& key : obj->config.keys()) {
    stream << "  <" << METADATA_TAG << " " << KEY_ATTR << "=\"" << key
           << "\" " << VALUE_ATTR << "=\"" << obj->config.opt_serialize(key) << "\"/>\n";
}

// Per-volume config
for (const auto& key : volume->config.keys()) {
    stream << "   <" << METADATA_TAG << " " << KEY_ATTR << "=\"" << key
           << "\" " << VALUE_ATTR << "=\"" << volume->config.opt_serialize(key) << "\"/>\n";
}
```

**Import** (Lines 899-904):
```cpp
if (!metadata.empty()) {
    for (auto &meta : metadata) {
        model_object->config.set_deserialize(meta.key, meta.value, config_substitutions);
    }
}
```

**Reusable Pattern for Feature #3:**
Add `flush_into_this_object_filaments` to PrintObjectConfig, and it will automatically serialize/deserialize via this mechanism.

---

### 4.4 Per-Plate Config Serialization

**PlateData Structure** (bbs_3mf.hpp:52-119):
```cpp
struct PlateData {
    int plate_index;
    std::string printer_model_id;
    std::string gcode_file;
    DynamicPrintConfig config;  // Per-plate configuration
    bool locked;
    // ... more fields
};
```

**Export** (Lines 7666-7813):
```xml
<plate>
  <metadata key="plate_id" value="[plate_index+1]"/>
  <metadata key="plate_name" value="[plate_name]"/>
  <metadata key="locked" value="true/false"/>
  <metadata key="bed_type" value="[enum_name]"/>
  <metadata key="print_sequence" value="[enum_name]"/>
  <metadata key="gcode_file" value="..."/>
</plate>
```

**Import** (Lines 4151-4360):
```cpp
bool _BBS_3MF_Importer::_handle_start_config_metadata(...)
{
    std::string key = bbs_get_attribute_value_string(attributes, num_attributes, KEY_ATTR);
    std::string value = bbs_get_attribute_value_string(attributes, num_attributes, VALUE_ATTR);

    if (key == PLATE_NAME_ATTR) {
        if (m_curr_plater)
            m_curr_plater->plate_name = value;
    }
    else if (key == NEW_FIELD_ATTR) {  // ← Add new fields here
        if (m_curr_plater)
            m_curr_plater->new_field = value;
    }
    // ... more fields
}
```

**Reusable Pattern for Feature #2 (Per-Plate Settings):**

1. Add constants (Line ~300):
   ```cpp
   static constexpr const char* PRINTER_PRESET_ATTR = "printer_preset";
   static constexpr const char* FILAMENT_PRESETS_ATTR = "filament_presets";
   ```

2. Extend PlateData (bbs_3mf.hpp:52):
   ```cpp
   struct PlateData {
       std::string printer_preset_name;
       std::vector<std::string> filament_preset_names;
   };
   ```

3. Export logic (Line ~7750):
   ```cpp
   if (!plate_data->printer_preset_name.empty()) {
       stream << "    <" << METADATA_TAG << " " << KEY_ATTR << "=\""
              << PRINTER_PRESET_ATTR << "\" " << VALUE_ATTR << "=\""
              << xml_escape(plate_data->printer_preset_name) << "\"/>\n";
   }
   ```

4. Import logic (Line ~4350):
   ```cpp
   else if (key == PRINTER_PRESET_ATTR) {
       if (m_curr_plater)
           m_curr_plater->printer_preset_name = value;
   }
   ```

---

### 4.5 Helper Functions for Serialization

**Attribute Reading** (Lines 428-465):
```cpp
const char* bbs_get_attribute_value_charptr(...)    // Returns nullptr if not found
std::string bbs_get_attribute_value_string(...)     // Returns empty if not found
int bbs_get_attribute_value_int(...)                // Returns 0 if not found
float bbs_get_attribute_value_float(...)            // Returns 0.0 if not found
bool bbs_get_attribute_value_bool(...)              // Returns false if not found
```

**XML Escaping** (Line 7617):
```cpp
std::string xml_escape(const std::string &text);
```

**Vector Serialization** (Lines 7691-7698):
```cpp
// Space-separated integers
template<typename T>
void add_vector(std::ostream& stream, const std::vector<T>& vec) {
    for (size_t i = 0; i < vec.size(); ++i) {
        if (i > 0) stream << " ";
        stream << vec[i];
    }
}
```

**Vector Deserialization** (Line 4933):
```cpp
auto filament_map = get_vector_from_string(value);
```

---

## 5. Code Reuse Opportunities

### 5.1 For Feature #3/#4 (Material-Specific Flushing)

**Reusable Code:**

1. **Config Option Definition Pattern:**
   - Copy `flush_into_infill` definition (PrintConfig.cpp:6471-6478)
   - Adapt for `wipe_tower_filaments`, `support_flush_filaments`, `infill_flush_filaments`

2. **WipingExtrusions Filtering:**
   - Reuse `is_overriddable()` logic (ToolOrdering.cpp:1564-1576)
   - Add filament array check before existing checks

3. **GUI CheckListBox:**
   - Reuse `wxCheckListBoxComboPopup` pattern (wxExtensions.hpp:95-128)
   - Bind to ConfigOptionInts via Field.cpp patterns

4. **Serialization:**
   - ConfigOptionInts automatically serializes/deserializes
   - No custom serialization code needed

### 5.2 For Feature #5 (Hierarchical Grouping)

**Reusable Code:**

1. **ModelObject/ModelVolume Pattern:**
   - Follow `ModelObject` structure (Model.hpp:354-435)
   - Add `ModelVolumeGroup` class with similar API
   - Reuse `add()`, `delete()`, iterator patterns

2. **GUI ObjectList:**
   - Study existing `itObject`, `itVolume` item types
   - Add `itVolumeGroup` item type following same pattern
   - Reuse context menu creation patterns

3. **3MF Serialization:**
   - Follow per-object metadata pattern (bbs_3mf.cpp:7558-7571)
   - Add `<volumegroups>` section in config XML
   - Reuse backward compatibility pattern (optional section)

4. **Selection Handling:**
   - Study `Selection::add()` patterns (Selection.cpp)
   - Extend to handle group selections

### 5.3 For Feature #6 (Cutting Plane)

**Reusable Code:**

1. **Gizmo Parameter UI:**
   - Study existing gizmo ImGUI patterns
   - Find slider/checkbox creation functions
   - Reuse parameter binding patterns

2. **Plane Rendering:**
   - Reuse existing cutting plane geometry code
   - Modify size calculation only

### 5.4 For Feature #2 (Per-Plate Settings)

**Reusable Code:**

1. **PlateData Extension:**
   - Follow existing PlateData field pattern (bbs_3mf.hpp:52)
   - Add preset name fields

2. **Config Resolution:**
   - Study `DynamicPrintConfig::apply()` merging logic
   - Create `resolve_config_for_plate()` following same pattern

3. **GUI Combobox:**
   - Reuse preset selection comboboxes from Plater
   - Bind to PlateData fields

4. **Serialization:**
   - Follow plate metadata export/import pattern (bbs_3mf.cpp:7666-7813, 4151-4360)
   - Add new optional metadata keys

---

## 6. Coding Standards Observed

### 6.1 Naming Conventions

**Classes:** PascalCase
- `WipeTower`, `ToolOrdering`, `ModelObject`, `PrintConfig`

**Methods:** snake_case
- `mark_wiping_extrusions()`, `plan_toolchange()`, `get_config_value()`

**Member Variables:** m_ prefix + snake_case
- `m_plan`, `m_layer_tools`, `m_wipe_tower_data`

**Constants:** snake_case or PascalCase (inconsistent)
- `VERSION_BBS_3MF`, `BBS_3MF_VERSION`

**Config Options:** snake_case
- `flush_into_infill`, `wipe_tower_filaments`, `support_filament`

### 6.2 Memory Management

**Smart Pointers:**
- Use `std::unique_ptr` for ownership
- Use `std::shared_ptr` for shared ownership
- Example: `std::unique_ptr<WipeTower::ToolChangeResult> m_wipe_tower_data.final_purge`

**Raw Pointers:**
- Used for non-owning references
- Example: `const PrintObject*` in maps, `ModelVolume* parent_volume`

**RAII Pattern:**
- Constructors initialize, destructors clean up
- Example: `ToolOrdering` constructor builds layer_tools

### 6.3 Threading & Performance

**TBB Usage:**
- Multi-threaded algorithms use `tbb::parallel_for`
- Be mindful of shared state
- Use atomic operations or mutexes for synchronization

**Performance Considerations:**
- Use static caches for config option lookups
- Prefer vector over list for sequential access
- Use `boost::container::small_vector` for small arrays (in-place optimization)

### 6.4 Error Handling

**Assertions:**
- Use `assert()` for internal invariants
- Example: `assert(m_sorted);` before accessing sorted data

**Graceful Degradation:**
- Missing config options return defaults (no throw)
- Missing 3MF metadata silently ignored
- Unknown enum values fall back to default

**Return Values:**
- Return bool for success/failure
- Return -1 or nullptr for "not found"
- Example: `get_support_extruder_overrides()` returns -1 if no override

### 6.5 Config Option Definition Pattern

**Standard Pattern:**
```cpp
// In PrintConfig.cpp:
def = this->add("option_name", coType);
def->label = L("User-visible label");
def->category = L("Category");
def->tooltip = L("Detailed tooltip text");
def->mode = comAdvanced;  // or comSimple, comExpert
def->min = 0;             // Optional bounds
def->max = 100;
def->default_value = new ConfigOptionType(default_val);
```

### 6.6 GUI Widget Creation Pattern

**Standard Pattern:**
```cpp
// Create option group
auto optgroup = page->new_optgroup(L("Section Name"), L"help_path");

// Simple option
optgroup->append_single_option_line("option_key", "help_path#anchor");

// Multi-option line
Line line = { L("Label"), L("Tooltip") };
line.append_option(optgroup->get_option("option1"));
line.append_option(optgroup->get_option("option2"));
optgroup->append_line(line);

// Change callback
optgroup->m_on_change = [this](t_config_option_key opt_key, boost::any value) {
    update_dirty();
    on_value_change(opt_key, value);
};
```

### 6.7 Serialization Pattern

**Export:**
```cpp
for (const auto& key : config.keys()) {
    stream << "<" << METADATA_TAG << " "
           << KEY_ATTR << "=\"" << key << "\" "
           << VALUE_ATTR << "=\"" << config.opt_serialize(key) << "\"/>\n";
}
```

**Import:**
```cpp
if (!metadata.empty()) {
    for (auto &meta : metadata) {
        config.set_deserialize(meta.key, meta.value, config_substitutions);
    }
}
```

---

## Summary

This exploration document provides:

1. **Understanding of existing multi-material/flushing architecture** - Know how WipeTower, WipingExtrusions, and ToolOrdering work together
2. **Config system patterns** - How to define, organize, and propagate configuration options
3. **GUI patterns** - How to create settings tabs, option widgets, per-object settings
4. **Serialization patterns** - How to save/load new data in 3MF files with backward compatibility
5. **Reusable code locations** - Specific file:line references to functions/patterns to reuse
6. **Coding standards** - Naming, memory management, error handling conventions to follow

All new feature implementations should follow these established patterns to ensure consistency, maintainability, and compatibility with the existing OrcaSlicer codebase.
