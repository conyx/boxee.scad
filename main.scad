include <BOSL2/std.scad>
include <BOSL2/hinges.scad>
include <BOSL2/joiners.scad>

include <constants.scad>
include <utils.scad>
include <compartments.scad>
include <connection.scad>
include <notches.scad>
include <slider.scad>
include <box.scad>
include <lid.scad>
include <magnets.scad>
include <hinges.scad>
include <latches.scad>
include <summary.scad>

/* [Main] */

// How the box and lid connect
lid_type = "slider"; // [no_lid: No lid, lip: Lip, magnets: Magnets, lip_magnets: Lip and magnets, latches: Latches, lip_latches: Lip and latches, hinges: Hinges, hinges_magnets: Hinges and magnets, hinges_latches: Hinges and latches, slider: Slider]

// Model detail in preview mode. Increase for better but slower results in preview mode.
model_detail_preview = 0.4; // [0:0.01:1]

// Model detail of the result STL. Increase for better but slower results when generating STL.
model_detail_stl = 0.9; // [0:0.01:1]

// Generate a summary plate with dimensions and accessory info (only in preview mode).
generate_summary_plate = true;

// Compartment dimensions as text. Format per row: "DEPTH, WIDTH, WIDTH, ...". Rows are separated by semicolon ";". The first number of each row is its DEPTH (Y), followed by WIDTHs (X) of compartments in that row. (TIP: Use "100, 100" for a single full-box compartment.)
compartments_dimensions = "50, 20, 55, 55, 20; 25, 37.5, 37.5, 37.5, 37.5";

// If true, rows are generated along Y axis instead of X axis.
compartments_transpose = false;

// Bottom part (box) height. The sum of the bottom and lid heights equals the total interior height of the container.
bottom_height = 25; // .1

// Lid height. The sum of the bottom and lid heights equals the total interior height of the container. This has no effect if slider lid is in use.
lid_height = 10; // .1

// Wall thickness. This adds to the outside dimensions of the box.
thickness = 2.4; // .1

/* [Separators] */

// Thickness of the walls between compartments (i.e., separators).
separator_thickness = 1.0; // .1

// Lowers separators from the top by this amount, creating shared open space above the compartments (0 = separators reach full height).
separators_z_offset = 0; // .1

// Whether corresponding separators should also be generated inside the lid. This has no effect if slider lid is in use.
separators_inside_lid = false;

/* [Rounding] */

// Box/lid corner outer radius (0 = sharp outer corner).
corner_outer_radius = 5; // .5

// Box/lid corner inner radius (0 = sharp inner corner).
corner_inner_radius = 2; // .5

// Compartment bottom corner radius (0 = sharp inner corner). WARNING: this could be slow.
compartment_bottom_radius = 0; // .5

/* [Slider lid] */

// The thickness of the slider lid. Adds overall height.
slider_lid_thickness = 2.4; // .1

// How deep the slider lid sits inside the box rail, as a percentage of wall thickness. Higher values make the lid more secure but the box harder to print.
slider_lid_rail_grip = 60; // [20:1:80]

// Shape of the notch pattern on top of the slider lid. "None" disables notches. "Full" does not form any shape and uses the full Y depth of the lid.
slider_lid_notches = "circle"; // [none: None, full: Full, circle: Circle, triangle: Triangle, square: Square, hexagon: Hexagon, teardrop: Teardrop, cross: Cross, heart: Heart]

// Number of notches cut into the slider lid.
slider_lid_notches_number = 6; // 1

// Width of each individual notch.
slider_lid_notch_width = 3; // 1

// Spacing between consecutive notches.
slider_lid_notches_spacing = 1; // .2

// Height of each notch as a percentage of the lid thickness. Lower values produce shallower notches, higher values cut deeper into the lid.
slider_lid_notch_height = 40; // [10:1:90]

// Offset of the notch pattern from the right edge of the lid. Increase to move notches further left.
slider_lid_notches_right_offset = 0; // 1

// Flip the notch shape along the X axis. Useful for reversing the direction of asymmetric shapes like triangle, teardrop or heart.
slider_lid_notches_shape_flip = false;

// Whether to add snap-lock bumps that hold the lid closed
slider_lid_snap_lock = true;

// How firmly the snap lock holds (0 = loosest, 1 = firmest). Higher values produce larger bumps.
slider_lid_snap_lock_firmness = 0.5; // [0:0.05:1]

// Extra clearance added to slider rail dimensions. Increase if the lid slides too tightly. WARNING: snap lock is optimized to default tolerance 0.1. If you adjust tolerance you might need to adjust "slider_lid_snap_lock_firmness" too.
slider_lid_tolerance = 0.1; // [0:0.01:0.3]

/* [Lip] */

// Height of lip above box top.
lip_height = 5; // .1

// Wall thickness of the lip.
lip_thickness = 0.8; // .1

// Extra clearance added to lip dimensions. Increase if the lid fits too tightly. Decrease for more firm friction fit effect.
lip_tolerance = 0.1; // [0:0.01:0.3]

/* [Magnets] */

// # of magnets
magnets_number = 2; // [2: 2 magnets, 4: 4 magnets]

// Magnet diameter
magnet_diameter = 3;  // .1

// Magnet height
magnet_height = 3;  // .1

// Magnet holder diameter (must be greater than magnet_diameter)
magnet_holder_diameter = 5;  // .1

// Extra height for (super) glue to secure magnets in their holes
magnet_glue_height = 0.5; // [0.1:0.1:3]

// Whether to generate a magnet closure that fills the space above the magnet. IMPORTANT: You have to pause printing at a specific layer to insert magnets. See console output or the summary plate for instructions.
magnet_generate_closure = false;

// Height of the magnet closure.
magnet_closure_height = 0.45; // [0.1:0.05:1]

// Extra clearance added to magnet hole dimensions. Increase if magnets don't fit.
magnet_tolerance = 0.1; // [0:0.01:0.3]

/* [Hinges] */

// How hinge segments should be joined.  "Snap-fit" hinges assemble after printing without hardware (parts snap together), "Simple pin" creates a simple hole with a specific diameter, "Screw with nut" additionally creates counterbores for flat the screw head and nut, "Self-tapping screw" creates a countersink for the conical screw head and adjusts the last segment for self-tapping.
hinge_join_type = "snap_fit"; // [snap_fit: Snap-fit, pin: Simple pin, screw_nut: Screw with nut, screw_self_tap: Self-tapping screw]

// # of hinges
hinges_number = 2; // [1:1:10]

// # of segments of each hinge
hinge_segments = 3; // [2:1:30]

// Hinge segments ratio (ratio between lid and box hinge segment lengths; use 1 for equal length)
hinge_segments_ratio = 1; // [0.2:0.1:5]

// Hinge knuckle diameter
hinge_knuckle_diameter = 6;  // .1

// Whether the last hinge should be mirrored (e.g., for easier screwdriver access or a symmetric hinge pair)
hinge_flip_last = false;

// Angle of the hinge arm measured down from the vertical. 90 = No arm.
hinge_arm_angle = 45; // [30:1:90]

// Additional offset between the hinge and the box/lid
hinge_mount_gap = 0.25; // .05

// Gap between hinge segments. WARNING: snap-fit hinge is optimized to default gap 0.15. If you adjust the gap you might need to adjust "hinge_snap_fit_firmness" too.
hinge_segments_gap = 0.15; // .05

/* [Hinges / snap-fit] */

// Length of each snap-fit hinge
hinge_snap_fit_length = 25;

// How firmly the snap-fit hinge clips together (0 = easiest to assemble and disassemble, 1 = hardest to assemble but firmest hold).
hinge_snap_fit_firmness = 0.5; // [0:0.05:1]

/* [Hinges / simple pin] */

// Length of each hinge (also the minimum length of the hinge pin)
hinge_pin_length = 25;

// Diameter of the hinge pin (budget tip: use 1.75 for a filament string)
hinge_pin_diameter = 1.75; // .05

// Extra clearance added to the pin hole. Increase if the pin doesn't fit.
hinge_pin_tolerance = 0.15; // [0:0.01:0.3]

/* [Hinges / screw with nut] */

// Hinge screw diameter
hinge_screw_diameter = 2.5;  // .1

// Hinge screw length (without head)
hinge_screw_length = 25; // .1

// Hinge screw head diameter
hinge_screw_head_diameter = 4; // .1

// Hinge screw head width (depth of the screw head counterbore)
hinge_screw_head_width = 1.8; // .1

// Hinge screw nut size (i.e., the spanner/wrench size needed)
hinge_nut_size = 4; // .1

// Hinge screw nut width (the nut counterbore is cut 1.5x deeper than this, so the nut seats firmly on the screw)
hinge_nut_width = 1.8; // .1

// Extra clearance added to screw/nut hardware fit (screw hole, head and nut counterbores). Increase if hardware doesn't fit.
hinge_screw_nut_tolerance = 0.1; // [0:0.01:0.3]

/* [Hinges / self-tapping screw] */

// Type of the self-tapping screw (ISO/metric and UTS/imperial standards)
hinge_self_tap_screw_type = "M2"; // [M1.6: M1.6 {ISO / metric}, M1.8: M1.8 {ISO / metric}, M2: M2 {ISO / metric}, M2.5: M2.5 {ISO / metric}, M3: M3 {ISO / metric}, M3.5: M3.5 {ISO / metric}, M4: M4 {ISO / metric}, M5: M5 {ISO / metric}, M6: M6 {ISO / metric}, #0: #0 {UTS / imperial}, #1: #1 {UTS / imperial}, #2: #2 {UTS / imperial}, #3: #3 {UTS / imperial}, #4: #4 {UTS / imperial}, #5: #5 {UTS / imperial}, #6: #6 {UTS / imperial}, #8: #8 {UTS / imperial}, #10: #10 {UTS / imperial}, #12: #12 {UTS / imperial}]

// Length of the self-tapping screw (including head)
hinge_self_tap_screw_length = 25;

// Maximum depth of the tapped portion of the screw hole in the last hinge segment.
hinge_self_tap_screw_tap_depth = 10; // .5

// Safety gap between the screw tip and the edge of the hinge
hinge_self_tap_screw_safety_gap = 1; // .5

/* [Latches] */

// # of latches
latches_number = 1; // [1:1:10]

// Width of each latch (X axis)
latch_x_width = 20; // .1

// Height of each latch (Z axis)
latch_z_height = 15; // .1

// Thickness of each latch (Y axis). Also determines the hinge knuckle diameter.
latch_y_thickness = 6; // [3.5:0.1:10]

// Whether to add snap-lock bumps that hold the latch closed
latch_snap_lock = true;

// How firmly the snap lock holds (0 = loosest, 1 = firmest). Higher values produce larger bumps.
latch_snap_lock_firmness = 0.5; // [0:0.05:1]

// Angle of the support which holds box-part of the latch measured down from the vertical. 90 = No support.
latch_support_angle = 45; // [30:1:90]

// Angle of the latch hinge arm measured down from the vertical. 90 = No arm.
latch_hinge_arm_angle = 45; // [30:1:90]

// Gap between latch hinge segments. WARNING: snap-fit hinge is optimized to default gap 0.15. If you adjust the gap you might need to adjust "latch_hinge_snap_fit_firmness" too.
latch_hinge_segments_gap = 0.15; // .05

// How firmly the latch's snap-fit hinge clips together (0 = easiest to assemble and disassemble, 1 = hardest to assemble but firmest hold).
latch_hinge_snap_fit_firmness = 0.5; // [0:0.05:1]

// Extra clearance added to latch dovetail dimensions. Increase if the latch is too tight. WARNING: snap lock is optimized to default tolerance 0.1. If you adjust tolerance you might need to adjust "latch_snap_lock_firmness" too.
latch_tolerance = 0.1; // [0:0.01:0.3]

/* [Connection groove / bump] */

// Connection type on top of the box/lid wall: bump is the smaller protrusion, groove is the larger channel that receives it. Has no effect if: 1) slider lid or no lid is generated, 2) lip is generated, or 3) bump or groove percentage is zero.
connection_type = "bump_box"; // [off: Off, bump_box: Bump on box & groove on lid, bump_lid: Bump on lid & groove on box]

// Groove diameter as percentage of wall thickness. Must be >= bump percentage.
connection_groove_percentage = 80; // [0:1:100]

// Bump diameter as percentage of wall thickness. Must be <= groove percentage.
connection_bump_percentage = 60; // [0:1:100]

// Vertical scale of the bump/groove cross-section as a percentage. 100% = full circle, 50% = flattened to half height in Z.
connection_height_percentage = 90; // [50:1:100]

/* [Surface] */

// Where lid notches (for easier lid opening) should be generated. This has no effect on the sides where hinges are mounted. Also, this has no effect if slider lid is in use.
lid_notches = "all"; // [no: None,x:X sides only, y:Y sides only, all:Both X and Y sides]

// # of lid notches
lid_notches_number = 2;

// Lid notch spacing
lid_notches_spacing = 1.5; // .1

/* [Hidden] */

$preview = $preview; // https://github.com/openscad/openscad/issues/6867

$fs = pow(10, -get_model_detail()); // 1 = min detail, 0.1 = max detail
$fa = pow(10, 1 - get_model_detail()); // 10 = min detail, 1 = max detail

// Generate box
box();

// Generate the lid
lid();

// Magnet holders
magnets();

// Hinges
hinges();

// Latches
latches();

// Output summary
summary();
