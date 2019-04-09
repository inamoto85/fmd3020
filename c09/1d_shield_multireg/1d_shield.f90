program shield_1d
    !
    ! Program that simulates the particle transport through a 1D shield using Monte Carlo methods.
    ! Multi-region version
    !
    ! Author: Edgardo Doerner, edoerner@fis.puc.cl
    !
    use mod_rng
    use mod_mfp
    use mod_scatt

implicit none

    ! Geometry parameters
    integer, parameter :: nreg = 3                              ! number of region in the 1D shield
    real, dimension(nreg) :: xthick = (/0.1, 0.1, 0.1/)         ! thickness of the 1D shield (cm)
    real, dimension(nreg+1) :: xbounds = 0.0                    ! boundaries of the shield regions (cm)

    ! Transport parameters
    real, dimension(nreg) :: sigma_t = (/0.1, 10.0, 100.0/)     ! Total interaction cross section (cm-1)
    real, dimension(nreg) :: sigma_a = (/0.01, 0.1, 10.0/)      ! Absorption cross section (cm-1)
    real, dimension(nreg) :: sigma_s = (/0.09, 9.9, 90.0/)      ! Scattering cross section (cm-1)

    ! Particle parameters
    real, parameter :: xin = 0.0        ! initial position (cm)
    real, parameter :: uin = 1.0        ! initial direction
    real, parameter :: wtin = 1.0       ! statistical weight
    integer, parameter :: irin = 1         ! initial region

    integer :: ir
    real :: x, u, wt

    ! Simulation parameters
    integer, parameter :: nhist = 1000

    ! Scoring variables
    real, dimension(0:nreg+1) :: score = 0.0    ! score(0) : reflection
                                                ! score(1:nreg) : absorption
                                                ! score(nreg+1) : transmission

    integer :: i, ihist 
    real :: pstep   ! distance to next interaction 
    real :: dist    ! distance to boundary along particle direction 
    real :: rnno 
    real :: start_time, end_time

    call cpu_time(start_time)

    ! Initialize RNG
    call rng_init(20180815)

    ! Print some info to console
    write(*,'(A, I15)') 'Number of histories : ', nhist

    do i = 1,nreg
        !TODO_statement
        write(*,'(A, I5, A)') 'For region ', i, ':'
        write(*,'(A, F15.5)') 'Total interaction cross-section (cm-1): ', sigma_t(i)
        write(*,'(A, F15.5)') 'Absoption interaction cross-section (cm-1): ', sigma_a(i)
        write(*,'(A, F15.5)') 'Scattering interaction cross-section (cm-1): ', sigma_s(i)
        write(*,'(A, F15.5)') '1D shield thickness (cm): ', xthick(i)
    enddo
    
    ! Initialize simulation geometry.
    write(*,'(A)') 'Region boundaries (cm):'
    write(*,'(F15.5)') xbounds(1)
    do i = 1,nreg
        xbounds(i+1) = xbounds(i) + xthick(i)
        write(*,'(F15.5)') xbounds(i+1)
    enddo
    

    ihist_loop: do ihist = 1,nhist
        
        ! Initialize history
        x = xin
        u = uin
        wt = wtin
        ir = irin

        ! Enter transport process
        transport_loop: do
            
            ! Distance to the next interaction.
            pstep = mfp(sigma_t(irin))

            ! Check expected particle step with geometry.
            if(u .lt. 0.0) then
                ! The particle goes to the front face of the shield.
                dist = (xbounds(ir) - x)/u

                ! Now check if the particle leaves current region.
                if(dist < pstep) then
                    pstep = dist
                    ir = ir - 1
                endif
            else if(u .gt. 0.0) then
                ! The particle goes to the back face of the shield.
                dist = (xbounds(ir+1) - x)/u

                ! Now check if the particle leaves current region.
                if(dist < pstep) then
                    pstep = dist
                    ir = ir + 1
                endif
            endif

            ! Check if the particle left the geometry.
            if(ir == 0) then
                ! The particle was reflected.
                score(ir) = score(ir) + wt
                exit
            else if(ir == nreg+1) then
                ! The particle was transmitted.
                score(ir) = score(ir) + wt
                exit
            endif

            ! Update position of particle.
            x = x + pstep*u

            ! Determine interaction type.
            rnno = rng_set()
            if(rnno .le. sigma_a(ir)/sigma_t(ir)) then
                ! The particle was absorbed.
                score(ir) = score(ir) + wt
                exit
            else
                ! The particle was scattered, get new direction.
                u = scatt(u)
            endif
            
        enddo transport_loop
    enddo ihist_loop

    ! Print results to console
    write(*,'(A,F15.5)') 'Reflection : ', score(0)/real(nhist)
    write(*,'(A,F15.5)') 'Absorption : ', sum(score(1:nreg))/real(nhist)
    write(*,'(A,F15.5)') 'Transmission : ', score(nreg+1)/real(nhist)

    ! Get elapsed time
    call cpu_time(end_time)
    write(*,'(A,F15.5)') 'Elapsed time (s) : ', end_time - start_time

end program shield_1d