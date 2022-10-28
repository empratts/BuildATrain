-- These are some style prototypes that the tutorial uses
-- You don't need to understand how these work to follow along
local styles = data.raw["gui-style"].default

styles["bat_content_frame"] = {
    type = "frame_style",
    parent = "inside_shallow_frame_with_padding",
    vertically_stretchable = "on"
}

styles["bat_content_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontally_stretchable = "on",
    horizontal_spacing = 16,
}

styles["bat_label_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontally_stretchable = "on",
    horizontal_spacing = 0,
    horizontal_align = "left"
}

styles["bat_go_flow"] = {
    type = "horizontal_flow_style",
    vertical_align = "center",
    horizontally_stretchable = "on",
    horizontal_spacing = 0,
    horizontal_align = "right"
}

styles["bat_content_textfield"] = {
    type = "textbox_style",
    width = 36
}
styles["bat_scroll_pane"] = {
    type = "scroll_pane_style",
    vertical_align = "center",
    maximal_height = "800"
 }


styles["bat_deep_frame"] = {
    type = "frame_style",
    parent = "slot_button_deep_frame",
    vertically_stretchable = "on",
    horizontally_stretchable = "on",
    top_margin = 16,
    left_margin = 8,
    right_margin = 8,
    bottom_margin = 4
}