# Left of Blue

```
# quick start
julia --project=. language/run.jl 3_egocentric_intrinsic rect_room_blue_wall_corner_prize
# result at language/outputs/rect_room_blue_wall_corner_prize/3_egocentric_intrinsic.png

# general usage
julia --project=. language/run.jl [language_variant] [spatial_reasoning_test]
# result at language/outputs/[language_variant]/[spatial_reasoning_test].png

language_variant options:
1_geocentric
2_geocentric_with_at
3_egocentric_intrinsic
4_egocentric_relative

spatial_reasoning_test options:
rect_room_blue_wall_center_prize
rect_room_blue_wall_corner_prize
rect_room_no_blue_wall_center_prize
rect_room_no_blue_wall_corner_prize
spatial_lang_test
square_room_blue_wall_center_prize
square_room_blue_wall_corner_prize
square_room_no_blue_wall_center_prize
square_room_no_blue_wall_corner_prize
```
