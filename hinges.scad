module knuckle_hinge_wrapper(length,
                             segs,
                             offset,
                             inner,
                             arm_angle,
                             gap,
                             seg_ratio,
                             knuckle_diam,
                             pin_diam,
                             snap_fit,
                             snap_fit_firmness,
                             tap_depth) {
  difference() {
    knuckle_hinge(length = length,
                  segs = segs,
                  offset = offset,
                  inner = inner,
                  arm_angle = arm_angle,
                  gap = gap,
                  seg_ratio = seg_ratio,
                  knuckle_diam = knuckle_diam,
                  pin_diam = pin_diam,
                  clear_top = true,
                  in_place = snap_fit,
                  tap_depth = tap_depth,
                  screw_head = "flat");
    if (snap_fit) {
      knuckle_hinge_snap_fit_sockets(length = length,
                                     segs = segs,
                                     offset = offset,
                                     inner = inner,
                                     gap = gap,
                                     seg_ratio = seg_ratio,
                                     knuckle_diam = knuckle_diam,
                                     pin_diam = pin_diam,
                                     firmness = snap_fit_firmness);
    }
  }
}

// Snap-fit sockets: per segment, a channel from the pin axis up to the barrel
// top (a hull of two pin-coaxial 45-degree cones) that the mating cone presses
// into radially and is gripped by. `firmness` shrinks the cone 0.35..0.55 mm
// (smaller = firmer). Layout mirrors knuckle_hinge() so each socket lands where
// a mating cone seats.
module knuckle_hinge_snap_fit_sockets(length,
                                      segs,
                                      offset,
                                      inner,
                                      gap,
                                      seg_ratio,
                                      knuckle_diam,
                                      pin_diam,
                                      firmness) {
  // segment layout, mirroring knuckle_hinge()
  outer_segments_number = ceil(segs / 2);
  inner_segments_number = floor(segs / 2);
  outer_segment_length  = gap
                          + (length - (segs - 1) * gap)
                          / (outer_segments_number + inner_segments_number * seg_ratio);
  inner_segment_length  = gap
                          + (length - (segs - 1) * gap)
                          / (outer_segments_number + inner_segments_number * seg_ratio)
                          * seg_ratio;
  segments_number       = inner ? inner_segments_number : outer_segments_number;
  segment_spacing       = outer_segment_length + inner_segment_length;
  // even counts shift half a segment to stay centred
  even_segments_x_shift = segs % 2 == 1 ? 0
                        : inner ? outer_segment_length / 2
                        : inner_segment_length / 2;
  segment_body_length   = (inner ? inner_segment_length : outer_segment_length) - gap;

  // socket cone = mating cone (base radius pin_diam/2, 45 degrees) shrunk by
  // firmness so it grips the male cone (smaller = firmer)
  shrink      = lerp(0.35, 0.55, firmness);
  cone_radius = pin_diam / 2 - shrink;
  cone_height = pin_diam / 2 * tan(45) - shrink;
  assert(cone_radius > 0 && cone_height > 0,
         "snap-fit socket collapsed: pin_diam too small for this firmness");

  // BOSL2 cuts the in_place cone's spike at 80% of its height (flat tip = 20% of
  // the base radius). Match that on the seat cone so the mating cone's flat tip
  // seats firmly instead of jamming on a sharp apex.
  spike_keep      = 0.8;
  seat_height     = cone_height * spike_keep;
  seat_tip_radius = cone_radius * (1 - spike_keep);

  // the socket opens on the +X face (outer) / -X face (inner) of each segment
  socket_face_x_offset = (inner ? -1 : 1) * (segment_body_length / 2 + SWO);
  pin_z        = offset;
  barrel_top_z = offset + knuckle_diam / 2;

  // knuckle_hinge() runs segments along -X by index, so step copies likewise
  left(even_segments_x_shift)
    xcopies(n = segments_number, spacing = -segment_spacing) {
      // the hinge's far end has no mating cone, so it needs no socket
      is_edge = (!inner && segs % 2 == 1 && $idx == 0) ||
                (inner && segs % 2 == 0 && $idx == segments_number - 1);
      if (!is_edge) {
        // a spike-cut seat on the pin axis, hulled up to a full lead-in cone
        // at the barrel top: the channel the mating cone presses down into
        hull()
          for (c = [[pin_z,        seat_height, seat_tip_radius],  // seat (spike-cut)
                    [barrel_top_z, cone_height, 0]])               // lead-in (full cone)
            let (z = c[0], cone_len = c[1], tip_radius = c[2])
              // base on the receiving face, tip pointing into the segment
              translate([socket_face_x_offset, 0, z])
                xcyl(l = cone_len,
                     r1 = inner ? cone_radius : tip_radius,
                     r2 = inner ? tip_radius : cone_radius,
                     anchor = inner ? LEFT : RIGHT);
      }
    }
}

module hinge(is_box_hinge) {
  screw_head_cut_h = hinge_screw_head_width + 2*hinge_hardware_tolerance;
  screw_head_cut_d = hinge_screw_head_diameter + 2*hinge_hardware_tolerance;
  screw_nut_cut_h = hinge_nut_width + 2*hinge_hardware_tolerance;
  screw_nut_cut_id = hinge_nut_size + 2*hinge_hardware_tolerance;

  color(OUTSIDE_ACCESSORIES_COLOR)
  difference() {
    xrot(-90) zrot(180)
      knuckle_hinge_wrapper(
        length = get_hinge_length(),
        segs = hinge_segments,
        offset = get_hinge_knuckle_offset(),
        knuckle_diam = hinge_knuckle_diameter,
        pin_diam = get_hinge_hole_diameter(),
        tap_depth = hinge_self_tap_screw_tap_depth,
        snap_fit = hinge_join_type == "snap_fit",
        snap_fit_firmness = hinge_snap_fit_firmness,
        gap = hinge_segments_gap,
        inner = !is_box_hinge,
        arm_angle = hinge_arm_angle,
        seg_ratio = hinge_segments_ratio,
        $slop = hinge_join_type != "snap_fit" ? hinge_hardware_tolerance : 0
      );

    // Screw head/nut hole in first segment
    if (hinge_join_type == "screw_nut") {
      x_offset = get_hinge_length()/2 - screw_head_cut_h/2 + SWO/2;
      y_offset = hinge_knuckle_diameter/2 + hinge_mount_gap;
      odd_segments = hinge_segments % 2 == 1;

        if (xor(!is_box_hinge, odd_segments)) {
          move([x_offset * (is_box_hinge ? -1 : 1), y_offset, 0])
            regular_prism(
              6,
              h = screw_nut_cut_h + SWO,
              id = screw_nut_cut_id,
              orient = RIGHT
            );
        }

        if (is_box_hinge) {
          move([x_offset, y_offset, 0])
          xcyl(h = screw_head_cut_h + SWO,
               d = screw_head_cut_d);
        }
    }
  }
}

module hinges() {
  // Hinge-related assertions (only when hinges are used)
  if (get_generate_hinges()) {
    assert(hinges_number * get_hinge_length() <= get_x_width_outside(),
           str("Total hinge length exceeds box width. ",
               "Total hinge length: ", hinges_number * get_hinge_length(), "mm, ",
               "box width: ", get_x_width_outside(), "mm"));

    if (hinge_join_type == "snap_fit") {
      assert(hinge_segments >= 3,
             str("Snap-fit hinge requires at least 3 segments. ",
                 "Current segments: ", hinge_segments));
    }

    if (hinge_join_type == "screw_nut") {
      screw_head_cut_diameter = hinge_screw_head_diameter + 2*hinge_hardware_tolerance;
      screw_nut_cut_diameter = (hinge_nut_size + 2*hinge_hardware_tolerance) / cos(30);

      assert(hinge_knuckle_diameter >= screw_head_cut_diameter,
             str("hinge_knuckle_diameter is too small for screw head. ",
                 "Knuckle diameter: ", hinge_knuckle_diameter, "mm, ",
                 "screw head diameter (with tolerance): ", screw_head_cut_diameter, "mm"));

      assert(hinge_knuckle_diameter >= screw_nut_cut_diameter,
             str("hinge_knuckle_diameter is too small for screw nut. ",
                 "Knuckle diameter: ", hinge_knuckle_diameter, "mm, ",
                 "nut outer diameter (with tolerance): ", screw_nut_cut_diameter, "mm"));
    }
  }

  if (get_generate_hinges()) {
    // Calculate spacing for equal distribution along X axis
    hinge_spacing = (get_x_width_outside() - hinges_number * get_hinge_length()) / (hinges_number + 1);

    box_center_x = -(get_x_width_outside()/2 + get_box_x_margin());
    lid_center_x = get_x_width_outside()/2 + get_lid_x_margin();
    hinge_y = get_y_depth_outside()/2;

    for (i = [0 : hinges_number - 1]) {
      hinge_x_offset = (i + 1) * hinge_spacing + (i + 0.5) * get_hinge_length() - get_x_width_outside()/2;

      // Box hinge at top of box
      move([box_center_x + hinge_x_offset, hinge_y, get_box_height_outside()])
      mirror([hinge_flip_last && i == 0 ? 1 : 0, 0, 0])
        hinge(is_box_hinge = true);

      // Lid hinge at top of lid
      move([lid_center_x + hinge_x_offset, hinge_y, get_lid_height_outside()])
      mirror([hinge_flip_last && i == hinges_number - 1 ? 1 : 0, 0, 0])
        hinge(is_box_hinge = false);
    }
  }
}
