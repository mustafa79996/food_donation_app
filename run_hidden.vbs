Set WshShell = CreateObject("WScript.Shell")
WshShell.CurrentDirectory = "C:\Users\Admin\Documents\foodlink"
WshShell.Run "python serve_apk.py", 0, False
