; Program to plot WRF z-levs.  Takes output from plevs CDL file to change
;  values in NetCDF file because I'm lazy.
;
; Joseph B. Zambon
;  11 January 2021
;  jbzambon@ncsu.edu

infile = "wrf_control_d02.nc"
wrfout = addfile(infile,"r")

outfile = "wrf_control_d02_zlevs.nc"
system("/usr/bin/ncgen -o " + outfile + " ./zlevs.cdl")
out = addfile(outfile,"w")


z_levs = (/50., 100., 250., 500., 750., 1000., \
              1250., 1500., 1750., 2000., \
              2250., 2500., 2750., 3000., \
              3250., 3500., 3750., 4000., \
              4250., 4500., 4750., 5000., \
              5250., 5500., 5750., 6000., \
              6250., 6500., 6750., 7000., \
              7250., 7500., 7750., 8000. /)
zNum = dimsizes(z_levs)

outDateTime                = True       ;include a yyyymmddhh field
TimeUnits = "hours since 2001-01-01 00:00:00"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; load in the libraries
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

TimeChar = wrfout->Times
; -determine the number of dimensions for time
DimTimeChar = dimsizes(TimeChar)
nTime = DimTimeChar(0)
; -convert the wrfout time to a CF compliant time
;  "hours since 1901-01-01 00:00:00"
time_in = wrf_times_c(TimeChar, 1)
; -create an array indicating the year, month, day, hour, minute, second
utc_date = floattoint(ut_calendar(time_in, 0))
; -create the final variable for time with the units selected
time = (/ut_inv_calendar(utc_date(:,0), utc_date(:,1), utc_date(:,2),  \
utc_date(:,3), utc_date(:,4), utc_date(:,5),  \
TimeUnits, 0)/)  ;time
time@long_name = "Time"
time@standard_name = "time"
time@units = TimeUnits
time@calendar = "standard"
time!0 = "time"
time&time = time
utc_date!0 = "time"                  ;utc_date
utc_date&time = time
year = utc_date(:,0)
year@long_name = "Year"
year!0 = "time"
year&time = time
month = utc_date(:,1)
month@long_name = "Month"
month!0 = "time"
month&time = time
day = utc_date(:,2)
day@long_name = "Day"
day!0 = "time"
day&time = time
hour = utc_date(:,3)
hour@long_name = "Hour"
hour!0 = "time"
hour&time = time
minute = utc_date(:,4)
minute@long_name = "Minutes"
minute!0 = "time"
minute&time = time
; -convert the wrfout time to a DateTime integer for easy reading
if (outDateTime) then
DateTime = (/wrf_times_c(TimeChar, 3)/) ;time
DateTime@long_name = "Date and Time"
DateTime!0   = "time"
DateTime&time = time
end if

lat = (/wrfout->XLAT(0,:,:)/)        ;lat (mass)
DimLat = dimsizes(lat)
nS_N = DimLat(0)           ;S_N dimension
nW_E = DimLat(1)           ;W_E dimension

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("T_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    tc    = wrf_user_getvar(wrfout,"tk",n)    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(tc,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->T_p=plane
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("theta_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    tc    = wrf_user_getvar(wrfout,"th",n)    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(tc,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->theta_p=plane
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("Td_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    tc    = wrf_user_getvar(wrfout,"td",n)    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(tc,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->Td_p=plane
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("r_v_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    delete(tc)
    tc    = (/wrfout->QVAPOR(n,:,:,:)/)               ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(tc,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->r_v_p=plane
r_v_e = plane
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("q_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    delete(tc)
    tc = r_v_e(n,:,:,:) / (1 + r_v_e(n,:,:,:))
    do z=0,zNum-1
        plane(n,z,:,:) = r_v_e(n,z,:,:) / (1 + r_v_e(n,z,:,:))
    end do ; zlevs
end do; time
out->q_p=plane
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("rh_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    delete(tc)
    tc  = wrf_user_getvar(wrfout,"rh",n)    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(tc,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->rh_p=plane
delete(plane)

; U, V Wind components, speed, direction

uplane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
vplane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("u_tr_p, v_tr_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    uv_tr_e = (/wrf_user_getvar(wrfout,"uvmet",n)/)           ;u_tr and v_tr
    u_tr_e = uv_tr_e(0,:,:,:)                                  ;u_tr_e
    v_tr_e = uv_tr_e(1,:,:,:)                                  ;v_tr_e
    do z=0,zNum-1
        uplane(n,z,:,:) = wrf_user_intrp3d(u_tr_e,z_nt,"h",z_levs(z),0.,False)
        vplane(n,z,:,:) = wrf_user_intrp3d(v_tr_e,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->u_tr_p=uplane
out->v_tr_p=vplane

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("ws_p")
delete(u_tr_e)
delete(v_tr_e)
do n = 0, nTime-1
    u_tr_e = uplane(n,:,:,:)                                  ;u_tr_e
    v_tr_e = vplane(n,:,:,:)                                  ;v_tr_e
    do z=0,zNum-1
        plane(n,z,:,:) = sqrt(u_tr_e(z,:,:)^2 + v_tr_e(z,:,:)^2)
    end do ; zlevs
end do; time
out->ws_p=plane
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("wd_p")
delete(u_tr_e)
delete(v_tr_e)
r2d = 45.0/atan(1.0)
do n = 0, nTime-1
    u_tr_e = uplane(n,:,:,:)                                  ;u_tr_e
    v_tr_e = vplane(n,:,:,:)                                  ;v_tr_e
    do z=0,zNum-1
        plane(n,z,:,:) = atan2(u_tr_e(z,:,:), v_tr_e(z,:,:)) * r2d + 180.
    end do ; zlevs
end do; time
out->wd_p=plane
delete(u_tr_e)
delete(v_tr_e)
delete(plane)
delete(uplane)
delete(vplane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("w_e")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    w_e    = wrf_user_getvar(wrfout,"wa",n)    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(w_e,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->w_p=plane
delete(w_e)
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("r_cloud_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    r_cloud = (/wrfout->QCLOUD(n,:,:,:)/)                                 ;r_cloud
    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(r_cloud,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->r_cloud_p=plane
delete(r_cloud)
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("r_cloud_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    r_rain = (/wrfout->QRAIN(n,:,:,:)/)                                 ;r_cloud
    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(r_rain,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->r_rain_p=plane
delete(r_rain)
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("r_ice_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    r_ice = (/wrfout->QICE(n,:,:,:)/)                                 ;r_cloud
    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(r_ice,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->r_ice_p=plane
delete(r_ice)
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("r_snow_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    r_snow = (/wrfout->QSNOW(n,:,:,:)/)                                 ;r_cloud
    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(r_snow,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->r_snow_p=plane
delete(r_snow)
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("pvo_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    pvo   = wrf_user_getvar(wrfout,"pvo",n)    ; z on mass points
    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(pvo,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->pvo_p=plane
delete(pvo)
delete(plane)

plane = new((/nTime,zNum,nS_N,nW_E/), "float", "No_FillValue")
; -loop through the nTimes
print("avo_p")
do n = 0, nTime-1
    z_nt  = wrf_user_getvar(wrfout,"z",n)    ; z on mass points
    avo   = wrf_user_getvar(wrfout,"avo",n)    ; z on mass points
    ; z on mass points
    do z=0,zNum-1
        plane(n,z,:,:) = wrf_user_intrp3d(avo,z_nt,"h",z_levs(z),0.,False)
    end do ; zlevs
end do; time
out->avo_p=plane
delete(avo)
delete(plane)
