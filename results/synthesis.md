# Synthesis results

Flow: yosys synth_ice40 + nextpnr-ice40 --hx8k ct256, fmax = median of seeds 1, 2, 3.

| group | design | LUT4 | FF | carry | fmax (MHz) | gate depth | gates |
|---|---|---:|---:|---:|---:|---:|---:|
| mult | v2 ARRAY/RIPPLE N=4 | 33 | 17 | 0 | 149.8 | 18 | 92 |
| mult | v2 ARRAY/KOGGE_STONE N=4 | 33 | 17 | 0 | 149.8 | 14 | 92 |
| mult | v2 ARRAY/INFERRED N=4 | 32 | 17 | 3 | 187.2 | 16 | 86 |
| mult | v2 DADDA/RIPPLE N=4 | 33 | 17 | 0 | 153.3 | 18 | 92 |
| mult | v2 DADDA/KOGGE_STONE N=4 | 33 | 17 | 0 | 150.8 | 14 | 100 |
| mult | v2 DADDA/INFERRED N=4 | 30 | 17 | 6 | 192.8 | 13 | 88 |
| mult | numeric_std '*' N=4 | 49 | 17 | 3 | 161.0 |  |  |
| mult | v2 ARRAY/RIPPLE N=6 | 75 | 25 | 0 | 104.1 | 30 | 232 |
| mult | v2 ARRAY/KOGGE_STONE N=6 | 74 | 25 | 0 | 101.3 | 21 | 240 |
| mult | v2 ARRAY/INFERRED N=6 | 71 | 25 | 5 | 127.4 | 24 | 225 |
| mult | v2 DADDA/RIPPLE N=6 | 80 | 25 | 0 | 100.6 | 30 | 232 |
| mult | v2 DADDA/KOGGE_STONE N=6 | 79 | 25 | 0 | 102.9 | 19 | 262 |
| mult | v2 DADDA/INFERRED N=6 | 72 | 25 | 10 | 147.4 | 19 | 229 |
| mult | numeric_std '*' N=6 | 120 | 25 | 6 | 125.6 |  |  |
| mult | v2 ARRAY/RIPPLE N=8 | 132 | 33 | 0 | 69.4 | 42 | 436 |
| mult | v2 ARRAY/KOGGE_STONE N=8 | 132 | 33 | 0 | 69.4 | 28 | 452 |
| mult | v2 ARRAY/INFERRED N=8 | 134 | 33 | 7 | 98.1 | 32 | 428 |
| mult | v2 DADDA/RIPPLE N=8 | 149 | 33 | 0 | 78.0 | 42 | 436 |
| mult | v2 DADDA/KOGGE_STONE N=8 | 145 | 33 | 0 | 77.7 | 21 | 494 |
| mult | v2 DADDA/INFERRED N=8 | 134 | 33 | 14 | 122.2 | 22 | 434 |
| mult | numeric_std '*' N=8 | 211 | 33 | 9 | 97.8 |  |  |
| mult | v2 ARRAY/RIPPLE N=12 | 300 | 49 | 0 | 48.4 | 66 | 1036 |
| mult | v2 ARRAY/KOGGE_STONE N=12 | 297 | 49 | 0 | 47.5 | 41 | 1080 |
| mult | v2 ARRAY/INFERRED N=12 | 308 | 49 | 11 | 61.3 | 46 | 1029 |
| mult | v2 DADDA/RIPPLE N=12 | 354 | 49 | 0 | 51.1 | 66 | 1036 |
| mult | v2 DADDA/KOGGE_STONE N=12 | 346 | 49 | 0 | 51.1 | 26 | 1168 |
| mult | v2 DADDA/INFERRED N=12 | 331 | 49 | 22 | 91.2 | 27 | 1039 |
| mult | numeric_std '*' N=12 | 467 | 49 | 16 | 75.1 |  |  |
| mult | v2 ARRAY/RIPPLE N=16 | 550 | 65 | 0 | 33.1 | 90 | 1892 |
| mult | v2 ARRAY/KOGGE_STONE N=16 | 546 | 65 | 0 | 32.8 | 54 | 1964 |
| mult | v2 ARRAY/INFERRED N=16 | 559 | 65 | 15 | 45.0 | 60 | 1886 |
| mult | v2 DADDA/RIPPLE N=16 | 641 | 65 | 0 | 36.9 | 90 | 1892 |
| mult | v2 DADDA/KOGGE_STONE N=16 | 631 | 65 | 0 | 37.4 | 28 | 2104 |
| mult | v2 DADDA/INFERRED N=16 | 602 | 65 | 30 | 75.0 | 30 | 1900 |
| mult | numeric_std '*' N=16 | 819 | 65 | 24 | 67.9 |  |  |
| legacy | 2023 ARRAY N=8 | 141 | 32 | 0 | 48.8 | 54 | 432 |
| legacy | 2023 WALLACE N=8 | 159 | 32 | 0 | 60.2 | 51 | 432 |
| legacy | 2023 BAUGH N=8 | 137 | 33 | 0 | 72.5 |  |  |
| unit | 2023 sync unit (Wallace, tri-states) | 199 | 62 | 0 | 57.0 |  |  |
| unit | arith_unit_min ARRAY/RIPPLE PIPELINE=false | 157 | 33 | 0 | 71.8 |  |  |
| unit | arith_unit_min DADDA/KOGGE_STONE PIPELINE=false | 164 | 33 | 0 | 77.5 |  |  |
| unit | arith_unit_min DADDA/KOGGE_STONE PIPELINE=true | 160 | 48 | 0 | 82.1 |  |  |
| unit | arith_unit_min DADDA/INFERRED PIPELINE=true | 147 | 48 | 27 | 107.3 |  |  |
| unit | arith_unit ARRAY/RIPPLE | 423 | 163 | 3 | 55.4 |  |  |
| unit | arith_unit DADDA/KOGGE_STONE | 459 | 163 | 3 | 67.7 |  |  |
| unit | arith_unit DADDA/INFERRED | 420 | 163 | 65 | 86.1 |  |  |
| unit | arith_unit_serial DADDA/KOGGE_STONE | 485 | 221 | 6 | 63.3 |  |  |
