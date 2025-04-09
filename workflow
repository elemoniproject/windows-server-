name: Deploy Loan Service

on:
  push:
    branches:
      - master  # Runs when code is pushed to master
  workflow_dispatch: # Allows manual trigger

jobs:
  deploy:
    runs-on: self-hosted  # Runs on your Windows Server

    steps:
    - name: Checkout Repository
      uses: actions/checkout@v3

    - name: Set Up Java 17
      uses: actions/setup-java@v3
      with:
        distribution: 'temurin'
        java-version: '17'

    - name: Pull Latest Code
      run: |
        cd "C:\Users\Administrator\Downloads\loan"
        git reset --hard
        git pull origin master
      shell: powershell

    - name: Find Loan Service Directory
      run: |
        $basePath = "C:\Users\Administrator\Downloads"
        $matchingDirs = Get-ChildItem -Path $basePath -Directory | Where-Object { 
          (Test-Path "$($_.FullName)\pom.xml") -and ($_.Name -like "*loan*")
        }
        
        if ($matchingDirs.Count -gt 0) {
          $servicePath = $matchingDirs[0].FullName
          echo "FOUND_PATH=$servicePath" | Out-File -FilePath $env:GITHUB_ENV -Append
        } else {
          Write-Host "No project directory with pom.xml found for loan!"
          exit 1
        }
      shell: powershell

    - name: Build JAR File
      run: |
        cd "$env:FOUND_PATH"
        mvn clean package -DskipTests
      shell: powershell

    - name: Ensure Deployment Folder Exists
      run: |
        if (!(Test-Path -Path "C:\Deploy")) { New-Item -ItemType Directory -Path "C:\Deploy" }
      shell: powershell

    - name: Copy JAR File to Deployment Folder
      run: |
        Copy-Item -Path "$env:FOUND_PATH\target\loan-service.jar" -Destination "C:\Deploy\loan-service.jar" -Force
      shell: powershell

    - name: Restart Loan Service
      run: |
        $service = Get-Service -Name "loan-service" -ErrorAction SilentlyContinue
        if ($service) {
          Stop-Service -Name "loan-service" -Force
          Start-Service -Name "loan-service"
        } else {
          C:\Deploy\loan-service.exe install  # Ensure WinSW service is installed
          Start-Service -Name "loan-service"
        }
      shell: powershell

this one
