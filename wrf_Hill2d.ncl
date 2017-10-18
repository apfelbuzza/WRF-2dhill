
;   Example script to produce standard plots for a WRF hill2d run

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
;load "./WRFUserARW.ncl"

begin
;
; The WRF ARW input file.  
; This needs to have a ".nc" appended, so just do it.

  a = addfile("./wrfout_d01_0001-01-01_00:00:00.nc","r")

;  We generate plots, but what kind do we prefer?

   type = "x11"
;  type = "pdf"
;  type = "ps"
;  type = "ncgm"

  wks = gsn_open_wks(type,"plt_Hill2d")


; Set some Basic Plot options
    res = True
    res@MainTitle     = "WRF IDEAL 2D (CUSTOM TOPOGRAPHY 1)"          
    res@InitTime      = False
    res@Footer        = True

    pltres = True


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;  What times and how many time steps are in the data set?

  FirstTime = True
  times  = wrf_user_getvar(a,"times",-1) ; get times in the file
  ;times  = wrf_user_list_times(a)  ; get times in the file
  ntimes = dimsizes(times)          ; number of times in the file

  mdims = getfilevardimsizes(a,"P") ; get some dimension sizes for the file
  nd = dimsizes(mdims)

; The specific plane we want to plot data on

  plane = (/ 0., 0./)   ; (x,y) point for vertical plane
  angle = 90.0
  pii = 3.14159
  aspect_ratio = .7

; This is the big loop over all of the time periods to process.

  do it = 2,ntimes-1,2

    time = it
    res@TimeLabel                  = times(it)
    res@AspectRatio                = aspect_ratio



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First get the variables we will need        
; I removed the "_in" prefix to test something

  u   = wrf_user_getvar(a,"ua",time)    ; ua is u averaged to mass points
  v   = wrf_user_getvar(a,"va",time)    ; va is v averaged to mass points
  w   = wrf_user_getvar(a,"wa",time)    ; vertical velocity
  th  = wrf_user_getvar(a,"th",time)    ; get temperature (C)
  z   = wrf_user_getvar(a, "z",time)    ; grid point height

  ter    = wrf_user_getvar(a,"HGT",time)   ; need terrain height sometimes


; Calculating the max height for plotting and axes
    if ( FirstTime ) then                ; get height info for labels
      zmin = 0.
      zmax = max(z)/1000.
      nz   = floattoint(zmax/2 + 1)
      FirstTime = False
    end if
    z_values = fspan(zmin,zmax,nz)
    ;printVarSummary(z_values)
    dimzz = dimsizes(z_values)


  opts = False  

  ter_res = True

  ;res@tmYLMode    = "Explicit"
  ;res@tmYLValues  = fspan(0,5000,10)
  ;res@tmYLLabels  = sprintf("%.1f",fspan(0,5000,10))

  u_plane  = wrf_user_intrp3d( u,z,"v",plane,angle,False)
  v_plane  = wrf_user_intrp3d( v,z,"v",plane,angle,False)
  w_plane  = wrf_user_intrp3d( w,z,"v",plane,angle,False)
  th_plane = wrf_user_intrp3d(th,z,"v",plane,angle,False)

  ter_plane = wrf_user_intrp2d(ter,plane,angle,opts)
  ;X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)

  vel_normal  = u_plane*cos(2.*pii*angle/360.) - v_plane*sin(2.*pii*angle/360.)
  vel_tangent = u_plane*sin(2.*pii*angle/360.) + v_plane*cos(2.*pii*angle/360.)
  vel_tangent = vel_tangent - 10.


  dim = dimsizes(ter_plane)                      ; Find the data span - for use in labels
  zspan = dim(0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 ; Theta
      opts_th  = res
      opts_th@FieldTitle           = th@description
      opts_th@cnFillOn             = True
      opts_th@cnFillMode           = "AreaFill"  
      ;opts_th@ContourParameters    = 0.1
      opts_th@cnMissingValPerimOn     = False
      opts_th@cnMissingValFillColor   = -1
      opts_th@cnMissingValFillPattern = 0
      opts_th@gsnSpreadColorEnd    = -10 
      opts_th@PlotOrientation      = th_plane@Orientation
      contour_th     = wrf_contour(a,wks,th_plane,opts_th)

 ; Vertical Velocity
      opts_w   = res
      opts_w@FieldTitle            = w@description
      contour_w = wrf_contour(a,wks, w_plane,opts_w)

 ; Vel Tangent
      opts_vt   = res
      opts_vt@FieldTitle           = "Perturbation u"
      opts_vt@UnitLabel            = "m/s"
      contour_vt     = wrf_contour(a,wks,vel_tangent,opts_vt)
      
  ; Terrain Cross Section    
      opts_ter = ter_res
      ;opts_ter@trYMaxF = z_values(dimzz-2)*1000
      opts_ter@trYMaxF = 5000
      opts_ter@tiYAxisString = " Height (km)"
      opts_ter@tiXAxisString = " Cross-sectional distance (m)"
      opts_ter@gsnYRefLine = 0.0
      opts_ter@gsnAboveYRefLineColor = "black"
      opts_ter@gsnDraw = False
      opts_ter@gsnFrame = False
      opts_ter@tmYLMode    = "Automatic"
      opts_ter@tmYLValues              = fspan(0,zspan,nz)                    ; Create tick marks
      opts_ter@tmYLValues              = fspan(0,zspan,nz) 
      opts_ter@tmYLLabels              = sprintf("%.1f",fspan(zmin,zmax,nz))  ; Create labels   

      ;opts_ter@trYMaxF = 5000
      ;opts_ter@tmYLDataTopF = 5000
      ;opts_ter@tmYLValues  = fspan(0,5000,10)
      ;opts_ter@tmYLLabels  = sprintf("%.1f",fspan(0,5000,10))
      ;contour_ter = gsn_csm_xy(wks,ter_plane,opts_ter)
      contour_ter = gsn_csm_y(wks,ter_plane,opts_ter)


      plot = wrf_overlays(a,wks,(/contour_th, contour_w, contour_ter/),pltres)
      plot = wrf_overlays(a,wks,(/contour_th, contour_w, contour_ter/),pltres)
      ;plot = wrf_overlays(a,wks,(/ter/),ter_res)

  ;       ************************************************************

  end do  ;       end of the time loop

end
