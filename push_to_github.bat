@echo off
chcp 65001 >nul
echo ========================================
echo   Push Status Tracker to GitHub
echo ========================================
echo.

cd /d "c:\Users\Tawan\Documents\งาน (Work)\web\Status Tracker"

echo [1/6] Initializing Git repository...
git init
echo.

echo [2/6] Adding all files...
git add .
echo.

echo [3/6] Creating commit...
git commit -m "Add Status Tracker with completion percentage slideshow"
echo.

echo [4/6] Setting main branch...
git branch -M main
echo.

echo [5/6] Adding remote origin...
git remote add origin https://github.com/mediakids-productions/test.git 2>nul
git remote set-url origin https://github.com/mediakids-productions/test.git
echo.

echo [6/6] Pushing to GitHub...
git push -u origin main
echo.

echo ========================================
echo   Done! Check the output above.
echo ========================================
pause
