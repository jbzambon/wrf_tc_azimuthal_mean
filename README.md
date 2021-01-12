# wrf_tc_azimuthal_mean
Series of scripts to convert WRF output to pressure- and z-levels, then analyze the output for azimuthal means as a function of distance from TC center.

Joseph B. Zambon
  jbzambon@ncsu.edu
  12 January 2021

Program consists of a few NCL scripts to take your data and put on pressure- and z-levels (wrf_plevs.ncl and wrf_zlevs.ncl).

wrf_plevs.ncl is a self-contained file that allows users to select a number of variables and produce CF-compliant pressure-level (among others) output.  Credit to Matt Higgins for developing this extremely useful script!  To add/change pressure levels, just do so on lines 137-145.

wrf_zlevs.ncl requires a cdl file (zlevs.cdl) to generate output.  Define the z-levels (in m) in wrf_zlevs.ncl (lines #16-23) and make sure the number of z-levels in this file is correctly set in line #4 of zlevs.cdl.  Everything says pressure coordinates because I'm too lazy to change it but its actually height.

Run wrf_plevs.ncl and/or wrf_zlevs.ncl on your WRF-output to get pressure-/z-level data for use in the python scripts.

Azimuthal statistics are computed using radial_data.py (taken from https://www.lpl.arizona.edu/~ianc/python/radial_data.html).

TC_Polar_Coordinates-zlevs.ipynb and TC_Polar_Coordinates-plevs.ipynb modifications:
  define wrf_control for the location of the pressure-/z-level output from the NCL scripts.
  t_slice = the time-snapshot you wish to plot
  num_levs = the number of pressure-/z-levels defined above
  center = the exact center of your vortex-following domain.  Our domain in this example was 150,150 putting the center at 75,75
  npix = the width or length of the domain (square domains work best).  Somehow this results in 107 radials, which is input in the reshape function.
  km_rad = rad_stats.r *3  (3= 3km spacing)

Plots PNG images saved as wrf_control_zlevs_t or wrf_control_plevs_t with the time-slice added.  Should be a cinch if you want to loop this over time.
