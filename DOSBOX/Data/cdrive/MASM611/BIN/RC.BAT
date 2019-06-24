@echo>con      The project you are building requires RC.EXE.  RC.EXE is part of
@echo>con      the Microsoft Windows Software Development Kit (SDK).  If the SDK
@echo>con      is already installed on your machine, delete the file RC.BAT from 
@echo>con      your MASM BIN directory to eliminate this message and rebuild
@echo>con      the project.
@pause>con
@rc.exe %1 %2 %3 %4 %5 %6 %7 %8 %9