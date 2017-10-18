
;   Example script to produce plots for a WRF real-data run,
;   with the ARW coordinate dynamics option.
;   Plot data on a cross section
;   This script will plot data at a set angle through a specified point

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin
;
; The WRF ARW input file.  
; This needs to have a ".nc" appended, so just do it.
  a = addfile("wrfout_d01_0001-01-01_00:00:00.nc","r")


; We generate plots, but what kind do we prefer?
  ;type = "x11"
; type = "pdf"
 type = "ps"
; type = "ncgm"
  wks = gsn_open_wks(type,"plt_CrossSection_smooth1")


; Set some basic resources
  res = True
  res@MainTitle = "IDEALISED WRF (CUSTOM TOPOGRAPHY)"
  res@Footer = True
  
  pltres = True

  ter_res = True
  opts_ter = ter_res
  opts_ter@gsnYRefLine = 0.0
  opts_ter@gsnAboveYRefLineColor = "black"
  opts_ter@gsnDraw = False
  opts_ter@gsnFrame = False


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  FirstTime = True
  times  = wrf_user_getvar(a,"times",-1) ; get times in the file
  ntimes = dimsizes(times)          ; number of times in the file

  mdims = getfilevardimsizes(a,"P") ; get some dimension sizes for the file
  nd = dimsizes(mdims)

;---------------------------------------------------------------

  ter  = wrf_user_getvar(a,"ter",0)  
  ;xlon = wrf_user_getvar(a, "XLONG",0)


  do it = 0,ntimes-1,2             ; TIME LOOP

    print("Working on time: " + times(it) )
    res@TimeLabel = times(it)   ; Set Valid time to use on plots

    ;tc  = wrf_user_getvar(a,"tc",it)     ; T in C
    rh = wrf_user_getvar(a,"rh",it)      ; relative humidity

    z   = wrf_user_getvar(a, "z",it)     ; grid point height

    u   = wrf_user_getvar(a,"ua",it)    ; ua is u averaged to mass points
    v   = wrf_user_getvar(a,"va",it)    ; va is v averaged to mass points
    w   = wrf_user_getvar(a,"wa",it)    ; vertical velocity
    th  = wrf_user_getvar(a,"th",it)    ; get temperature (C)
    rain = wrf_user_getvar(a,"RAINNC",it)   ; get rain
    qvap = wrf_user_getvar(a,"QVAPOR",it)   ; Get the water vapor mixing ratio

    

    if ( FirstTime ) then                ; get height info for labels
      zmin = 0.
      zmax = max(z)/1000.
      nz   = floattoint(zmax/2 + 1)
      FirstTime = False
    end if
    z_values = fspan(zmin,zmax,nz)
    ;printVarSummary(z_values)
    dimzz = dimsizes(z_values)
    ;opts_ter@trYMaxF = z_values(dimzz-2)*1000  ; Does not produce correct terrain scaling???
    opts_ter@trYMaxF = 2000   ; set manually for now


;---------------------------------------------------------------

    ;do ip = 1, 3      	; we are doing 3 plots
			; all with the pivot point (plane) in the center of the domain
			; at angles 0, 45 and 90
 ;         
 ;                   |
 ;       angle=0 is  |
 ;                   |
 ;        
 ;       if(ip .eq. 1) then
          angle = 90.
;        end if
;        if(ip .eq. 2) then
;          angle = 0.
;        end if
;        if(ip .eq. 3) then
;          angle = 45.
;        end if

        plane = new(2,float)
        plane = (/ mdims(nd-1)/2, mdims(nd-2)/2 /)    ; pivot point is center of domain (x,y)
        opts = False  

        ;rh_plane = wrf_user_intrp3d(rh,z,"v",plane,angle,opts)
        ;tc_plane = wrf_user_intrp3d(tc,z,"v",plane,angle,opts)

        th_plane = wrf_user_intrp3d(th,z,"v",plane,angle,opts)
        u_plane = wrf_user_intrp3d(u,z,"v",plane,angle,opts)
        v_plane = wrf_user_intrp3d(v,z,"v",plane,angle,opts)
        w_plane = wrf_user_intrp3d(w,z,"v",plane,angle,opts)


        rh_plane = wrf_user_intrp3d(rh, z, "v", plane, angle, opts)

        ter_plane = wrf_user_intrp2d(ter,plane,angle,opts)
;        X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)

        th_plane2 = th_plane
        w_plane2 = w_plane
        cross_dims = dimsizes(th_plane2)
        rank = dimsizes(cross_dims)
        ;printVarSummary(rh_plane2)
        iz_do = 25
;        do iz = 0,24
;          iz_do = iz_do-1
;          do ix = 0,cross_dims(rank-1)-1
;            if ( ismissing(th_plane2(iz_do,ix)) ) then
;              th_plane2(iz_do,ix) = th_plane2(iz_do+1,ix)
;            end if
;            if ( ismissing(w_plane2(iz_do,ix)) ) then
;              w_plane2(iz_do,ix) = w_plane2(iz_do+1,ix)
;            end if
;          end do
;        end do

        dim = dimsizes(th_plane)                      ; Find the data span - for use in labels
        zspan = dim(0)

        
      ; Options for XY Plots
        opts_xy                         = res
        opts_xy@tiYAxisString           = "Height (km)"
        opts_xy@cnMissingValPerimOn     = True
        opts_xy@cnMissingValFillColor   = 0
        opts_xy@cnMissingValFillPattern = 11
        opts_xy@tmYLMode                = "Explicit"
        opts_xy@tmYLValues              = fspan(0,zspan,nz*2+10)                    ; Create tick marks
        opts_xy@tmYLLabels              = sprintf("%.1f",fspan(zmin,zmax,nz*2+10))  ; Create labels   
        opts_xy@tiXAxisFontHeightF      = 0.020
        opts_xy@tiYAxisFontHeightF      = 0.020
        opts_xy@tmXBMajorLengthF        = 0.02
        opts_xy@tmYLMajorLengthF        = 0.02
        opts_xy@tmYLLabelFontHeightF    = 0.015
        opts_xy@PlotOrientation         = w_plane@Orientation

  ;opts_xy@vpHeightF = 0.1 
  ;opts_xy@vpWidthF = 0.7 


      ; Plotting options for THETA
        opts_th = opts_xy
        ;opts_th@ContourParameters       = (/ 10., 90., 10. /)
        opts_th@pmLabelBarOrthogonalPosF = -0.07
        ;opts_th@cnFillOn                = True
        ;opts_th@gsnSpreadColorEnd    = -10 
        ;opts_th@cnFillColors            = (/"White","White","White", \
        ;                                    "White","Chartreuse","Green", \
        ;                                    "Green3","Green4", \
        ;                                    "ForestGreen","PaleGreen4"/)

      ; Plotting options for Vert Vel
        opts_w = opts_xy
        opts_w@cnInfoLabelOrthogonalPosF = 0.00
        opts_w@ContourParameters  = (/ 5. /)

      ; Plotting options for RAIN
        opts_rain = opts_xy
        opts_rain@cnFillOn = True
        opts_rain@gsnSpreadColorEnd    = -11

      ; Plotting options for RH
        opts_rh = opts_xy
        opts_rh@cnFillOn = True
        opts_rh@gsnSpreadColorEnd    = 11


      ; Get the contour info for the rh and temp
        contour_w = wrf_contour(a,wks,w_plane,opts_w)
        contour_th = wrf_contour(a,wks,th_plane,opts_th)
        contour_th2 = wrf_contour(a,wks,th_plane2,opts_th)
        contour_w2 = wrf_contour(a,wks,w_plane2,opts_w)

        contour_rh = wrf_contour(a,wks,rh_plane,opts_rain)

;Contour terrain cross section
        ;contour_ter = gsn_csm_xy(wks,X_plane,ter_plane,opts_ter)   ; No long in 
        contour_ter = gsn_csm_y(wks,ter_plane,opts_ter)


      ; MAKE PLOTS         
        ;plot = wrf_overlays(a,wks,(/contour_rh,contour_tc/),pltres)
        ;plot = wrf_overlays(a,wks,(/contour_rh,contour_tc,contour_ter/),pltres)
        ;plot = wrf_overlays(a,wks,(/contour_rh2,contour_tc2/),pltres)
        plot = wrf_overlays(a,wks,(/contour_w2,contour_rh,contour_ter/),pltres)

      ; Delete options and fields, so we don't have carry over
        delete(opts_w)
        delete(opts_th)
        delete(w_plane)
        delete(w_plane2)
        delete(th_plane)
        delete(th_plane2)
        delete(rh_plane)
        delete(ter_plane)

    ;end do  ; make next cross section

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  end do        ; END OF TIME LOOP

end
