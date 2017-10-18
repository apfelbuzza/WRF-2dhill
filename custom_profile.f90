program read_profile_data
implicit none

integer :: i
integer :: j = 1
integer, parameter :: ncol=2
integer, parameter :: nrow=501

real, dimension(1:nrow,1) :: height
real, dimension(1:nrow) :: dist

real, dimension(1:nrow) :: elev

open(unit=10, file="profile_test.txt")

do i = 1,nrow
  read(10, *) dist(i), height(i,1)
  print *, height(i,1)
  
end do

!print *, height

end program read_profile_data
