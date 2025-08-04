@echo off
setlocal enabledelayedexpansion

echo Orbital Pioneer Sprite Viewer (Simple Block Mode)
echo =================================================
echo.

:menu
echo Select a sprite to view:
echo 1. Command Pod Mk-I      14. Thrust Flame
echo 2. Liquid Engine Mk-I    15. Explosion  
echo 3. Fuel Tank S           18. Earth Icon
echo 4. Decoupler             19. Moon Icon
echo 5. Landing Leg           20. Stars Pattern
echo 6. Parachute             21. Cursor
echo 0. Exit
echo.
set /p choice="Enter choice: "

if "%choice%"=="0" goto :eof
if "%choice%"=="1" call :command_pod
if "%choice%"=="2" call :engine
if "%choice%"=="3" call :fuel_tank
if "%choice%"=="4" call :decoupler
if "%choice%"=="5" call :landing_leg
if "%choice%"=="6" call :parachute
if "%choice%"=="14" call :thrust_flame
if "%choice%"=="15" call :explosion
if "%choice%"=="18" call :earth_icon
if "%choice%"=="19" call :moon_icon
if "%choice%"=="20" call :stars
if "%choice%"=="21" call :cursor

echo.
pause
cls
goto :menu

:command_pod
echo.
echo Command Pod Mk-I (16x16) - Light blue capsule with windows
echo.
powershell -c "Write-Host '    00000000000000000000    ' -BackgroundColor DarkBlue"
powershell -c "Write-Host '  0000000000000000000000000  ' -BackgroundColor DarkBlue"
powershell -c "Write-Host ' 0000' -BackgroundColor DarkBlue -NoNewline; Write-Host '00000000000000000000' -BackgroundColor Blue -NoNewline; Write-Host '0000 ' -BackgroundColor DarkBlue"
powershell -c "Write-Host '0000' -BackgroundColor DarkBlue -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000000000000000' -BackgroundColor White -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000' -BackgroundColor DarkBlue"
powershell -c "Write-Host '0000' -BackgroundColor DarkBlue -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000000000000000' -BackgroundColor White -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000' -BackgroundColor DarkBlue"
powershell -c "Write-Host '0000' -BackgroundColor DarkBlue -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000000000000000' -BackgroundColor White -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000' -BackgroundColor DarkBlue"
powershell -c "Write-Host '0000' -BackgroundColor DarkBlue -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000000000000000' -BackgroundColor White -NoNewline; Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '0000' -BackgroundColor DarkBlue"
powershell -c "Write-Host '0000' -BackgroundColor DarkBlue -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Blue -NoNewline; Write-Host '0000' -BackgroundColor DarkBlue"
powershell -c "Write-Host '000000000000000000000000000000000' -BackgroundColor DarkBlue"
powershell -c "Write-Host '000000000000000000000000000000000' -BackgroundColor DarkBlue"
powershell -c "Write-Host '000000000000000000000000000000000' -BackgroundColor DarkBlue"
powershell -c "Write-Host ' 0000000000000000000000000000000 ' -BackgroundColor DarkBlue"
powershell -c "Write-Host '  00000000000000000000000000000  ' -BackgroundColor DarkBlue"
powershell -c "Write-Host '   000000000000000000000000000   ' -BackgroundColor DarkBlue"
powershell -c "Write-Host '    0000000000000000000000000    ' -BackgroundColor DarkBlue"
powershell -c "Write-Host '                                '"
goto :eof

:engine
echo.
echo Liquid Engine Mk-I (16x16) - Bell-shaped nozzle
echo.
echo                
powershell -c "Write-Host '  ' -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Gray -NoNewline; Write-Host '  '"
powershell -c "Write-Host ' ' -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Gray -NoNewline; Write-Host ' '"
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor Gray"
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor Gray"
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor Gray"
powershell -c "Write-Host ' ' -NoNewline; Write-Host '00000000' -BackgroundColor Gray -NoNewline; Write-Host '000000000000' -BackgroundColor Red -NoNewline; Write-Host '00000000' -BackgroundColor Gray -NoNewline; Write-Host ' '"
powershell -c "Write-Host '  ' -NoNewline; Write-Host '0000' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor Gray -NoNewline; Write-Host '  '"
powershell -c "Write-Host '   ' -NoNewline; Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000' -BackgroundColor Red -NoNewline; Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '   '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '00000000000000' -BackgroundColor Red -NoNewline; Write-Host '    '"
powershell -c "Write-Host '     ' -NoNewline; Write-Host '0000000000' -BackgroundColor Red -NoNewline; Write-Host '     '"
powershell -c "Write-Host '      ' -NoNewline; Write-Host '000000' -BackgroundColor Red -NoNewline; Write-Host '      '"
powershell -c "Write-Host '       ' -NoNewline; Write-Host '00' -BackgroundColor Red -NoNewline; Write-Host '       '"
echo                
echo                
echo                
goto :eof

:thrust_flame
echo.
echo Thrust Flame (16x16) - Animated flame effect
echo.
echo                
echo                
powershell -c "Write-Host '      ' -NoNewline; Write-Host '00000000' -BackgroundColor Yellow -NoNewline; Write-Host '      '"
powershell -c "Write-Host '     ' -NoNewline; Write-Host '000000000000' -BackgroundColor Yellow -NoNewline; Write-Host '     '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '0000000000000000' -BackgroundColor Yellow -NoNewline; Write-Host '    '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '000000000000' -BackgroundColor DarkYellow -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '    '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '   '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '   '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '   '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '00' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '  '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '   '"
powershell -c "Write-Host '     ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '00000000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '     '"
powershell -c "Write-Host '     ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '000000' -BackgroundColor Yellow -NoNewline; Write-Host '     '"
powershell -c "Write-Host '      ' -NoNewline; Write-Host '00000000' -BackgroundColor Yellow -NoNewline; Write-Host '      '"
powershell -c "Write-Host '       ' -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '       '"
echo                
goto :eof

:earth_icon
echo.
echo Earth Icon (16x16) - Blue oceans, green continents
echo.
powershell -c "Write-Host '    ' -NoNewline; Write-Host '0000000000000000' -BackgroundColor Blue -NoNewline; Write-Host '    '"
powershell -c "Write-Host '  ' -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Blue -NoNewline; Write-Host '  '"
powershell -c "Write-Host ' ' -NoNewline; Write-Host '00000000' -BackgroundColor Blue -NoNewline; Write-Host '0000000000000000' -BackgroundColor Green -NoNewline; Write-Host '00000000' -BackgroundColor Blue -NoNewline; Write-Host ' '"
powershell -c "Write-Host '000000' -BackgroundColor Blue -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Green -NoNewline; Write-Host '000000' -BackgroundColor Blue"
powershell -c "Write-Host '0000' -BackgroundColor Blue -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Green -NoNewline; Write-Host '0000' -BackgroundColor Blue"
powershell -c "Write-Host '0000' -BackgroundColor Blue -NoNewline; Write-Host '000000' -BackgroundColor Green -NoNewline; Write-Host '000000' -BackgroundColor White -NoNewline; Write-Host '000000000000' -BackgroundColor Green -NoNewline; Write-Host '000000' -BackgroundColor Blue"
powershell -c "Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '00000000' -BackgroundColor Green -NoNewline; Write-Host '000000' -BackgroundColor White -NoNewline; Write-Host '0000000000000000' -BackgroundColor Green -NoNewline; Write-Host '0000' -BackgroundColor Blue"
powershell -c "Write-Host '00' -BackgroundColor Blue -NoNewline; Write-Host '00000000' -BackgroundColor Green -NoNewline; Write-Host '000000' -BackgroundColor White -NoNewline; Write-Host '0000000000000000' -BackgroundColor Green -NoNewline; Write-Host '0000' -BackgroundColor Blue"
goto :eof

:moon_icon
echo.
echo Moon Icon (16x16) - Gray with darker craters
echo.
powershell -c "Write-Host '    ' -NoNewline; Write-Host '0000000000000000' -BackgroundColor White -NoNewline; Write-Host '    '"
powershell -c "Write-Host '  ' -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor White -NoNewline; Write-Host '  '"
powershell -c "Write-Host ' ' -NoNewline; Write-Host '000000000000000000000000000000' -BackgroundColor White -NoNewline; Write-Host ' '"
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor White"
powershell -c "Write-Host '00000000' -BackgroundColor White -NoNewline; Write-Host '000000' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000' -BackgroundColor White"
powershell -c "Write-Host '00000000' -BackgroundColor White -NoNewline; Write-Host '000000' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000' -BackgroundColor White -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00000000' -BackgroundColor White"
powershell -c "Write-Host '0000000000000000000000000000' -BackgroundColor White -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000' -BackgroundColor White"
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor White"
goto :eof

:stars
echo.
echo Stars Pattern (16x16) - Scattered stars
echo.
powershell -c "Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '                              '"
echo                                
powershell -c "Write-Host '        ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '                      '"
echo                                
powershell -c "Write-Host '                    ' -NoNewline; Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '          '"
echo                                
powershell -c "Write-Host '            ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '                  '"
echo                                
echo                                
powershell -c "Write-Host '                  ' -NoNewline; Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '            '"
echo                                
powershell -c "Write-Host '      ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '                        '"
echo                                
powershell -c "Write-Host '                            ' -NoNewline; Write-Host '00' -BackgroundColor Yellow -NoNewline; Write-Host '  '"
echo                                
powershell -c "Write-Host '          ' -NoNewline; Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '                    '"
goto :eof

:cursor
echo.
echo Cursor/Crosshair (16x16) - White crosshair with red center
echo.
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '000000' -NoNewline; Write-Host '00000000' -BackgroundColor Red -NoNewline; Write-Host '000000'"
powershell -c "Write-Host '000000' -NoNewline; Write-Host '00000000' -BackgroundColor Red -NoNewline; Write-Host '000000'"
powershell -c "Write-Host '000000' -NoNewline; Write-Host '00000000' -BackgroundColor Red -NoNewline; Write-Host '000000'"
powershell -c "Write-Host '000000' -NoNewline; Write-Host '00000000' -BackgroundColor Red -NoNewline; Write-Host '000000'"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
powershell -c "Write-Host '      0000000000      '"
goto :eof

:fuel_tank
echo.
echo Fuel Tank S (16x16) - Green fuel with silver ends
echo.
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Green -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Green -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Green -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Green -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Green -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor Gray"
goto :eof

:decoupler
echo.
echo Decoupler (16x8) - Orange with black separation ring
echo.
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor DarkYellow"
powershell -c "Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow"
powershell -c "Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow"
powershell -c "Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow"
powershell -c "Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow"
powershell -c "Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow"
powershell -c "Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor DarkRed -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow"
powershell -c "Write-Host '00000000000000000000000000000000' -BackgroundColor DarkYellow"
goto :eof

:landing_leg
echo.
echo Landing Leg (16x16) - Silver strut with foot pad
echo.
powershell -c "Write-Host '000000000000000000000000000000000' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '000000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '00' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '0000' -BackgroundColor DarkGray -NoNewline; Write-Host '0000000000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '00' -BackgroundColor Gray -NoNewline; Write-Host '00000000000000000000000000' -BackgroundColor DarkGray -NoNewline; Write-Host '00' -BackgroundColor Gray"
powershell -c "Write-Host '000000000000000000000000000000000' -BackgroundColor Gray"
goto :eof

:parachute
echo.
echo Parachute (16x16) - White canopy with suspension lines
echo.
powershell -c "Write-Host '0000000000000000000000000000000000' -BackgroundColor White"
powershell -c "Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor White"
powershell -c "Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor White"  
powershell -c "Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor White"
powershell -c "Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000000000000000' -BackgroundColor Black -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor White"
powershell -c "Write-Host '00' -BackgroundColor White -NoNewline; Write-Host '0000000000000000000000000000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor White"  
powershell -c "Write-Host '00000000000000000000000000000000000' -BackgroundColor White"
echo                                
powershell -c "Write-Host '              0000            ' -BackgroundColor Black"
powershell -c "Write-Host '              0000            ' -BackgroundColor Black"
powershell -c "Write-Host '              0000            ' -BackgroundColor Black"
powershell -c "Write-Host '              0000            ' -BackgroundColor Black"
powershell -c "Write-Host '              0000            ' -BackgroundColor Black"
powershell -c "Write-Host '              0000            ' -BackgroundColor Black"
echo                                
echo                                
goto :eof

:explosion
echo.
echo Explosion (16x16) - Fiery blast effect
echo.
echo                                
powershell -c "Write-Host '      ' -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '            ' -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '      '"
powershell -c "Write-Host '    ' -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '        ' -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '    '"
powershell -c "Write-Host '  ' -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '    ' -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '  '"
powershell -c "Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '000000' -BackgroundColor White -NoNewline; Write-Host '000000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow"
powershell -c "Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Red -NoNewline; Write-Host '000000' -BackgroundColor White -NoNewline; Write-Host '000000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow"
powershell -c "Write-Host '  ' -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000000000000000' -BackgroundColor Red -NoNewline; Write-Host '0000' -BackgroundColor DarkYellow -NoNewline; Write-Host '0000' -BackgroundColor Yellow -NoNewline; Write-Host '  '"
goto :eof

echo.
echo Sprite viewer complete!
pause