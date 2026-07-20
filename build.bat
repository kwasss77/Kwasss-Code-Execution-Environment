:: Kwasss Code Execution Environment 2026 ::
@echo off
chcp 65001 > nul
echo [kc2e]: Сборщик запущен.
del /q kc2e.obj
del /q kc2e.exe
echo [kc2e]: Успешно удалены предыдущие файлы: "kc2e.obj" и "kc2e.exe"
nasm -f win64 kc2e.asm -o kc2e.obj
GoLink /entry _start kc2e.obj kernel32.dll shell32.dll user32.dll
echo [kc2e]: Успешно собрано в kc2e.exe!
pause