# Ti60 example integration snapshot

`example_top.v` records the four-panel display integration: camera RGB565 is converted to grayscale, the Sobel binary result is written to the edge cache, and the bottom-right panel displays that result. `sim/tb_quad_full_frame.v` checks that a white edge sample reaches that panel.

The Ti60 example project and its vendor/IP sources are maintained outside this Git repository. This folder is an integration snapshot, not a standalone Efinity project. To apply it to the team project, copy `example_top.v` into that project's root and add the five `<efx:design_file>` entries from `Ti60_Demo_design_files.xml` under its `<efx:design_info>`. Copy the authoritative RTL files from `../rtl/` into the project's `src/sobel/` directory so the Efinity paths resolve.

`rtl/camera_sobel_top.v` now exposes `gray_pixel`, `pixel_valid`, `sof`, and `eol` for the display cache while preserving the existing `edge_gray` gradient output and `edge_out` binary output.

The source checks used for this integration are described in the repository README. The Efinity synthesis and board test still need to be run in the team's full project environment.
