##Android Sales Tracker App
An Android application built with Flutter to assist sales employees in logging call details and tracking demo locations. The app integrates with a powerful backend API hosted on AWS for seamless data management.

🚀 Features
User-Friendly Interface: Simple and intuitive UI for logging call details and GPS-based demo locations.
AWS Integration: Backend built with AWS services like Lambda, API Gateway, and RDS.
RESTful APIs: Secure and efficient API endpoints for data operations.
MySQL Database: Stores call logs and GPS locations with well-structured tables.
📋 Prerequisites
Flutter SDK installed on your development machine.
AWS Account to configure backend services.
MySQL Database for data storage.
🛠️ Installation
Clone the Repository
bash
Copy code
git clone https://github.com/<your-repository-name>.git  
cd <your-repository-name>  
Install Dependencies
Make sure Flutter and Dart are installed, then run:

bash
Copy code
flutter pub get  
Backend Setup
AWS Lambda Functions: Deploy Lambda functions to handle API requests.
API Gateway: Create RESTful endpoints using AWS API Gateway.
MySQL Database: Set up tables for storing call and location data:
sql
Copy code
CREATE TABLE call_details (  
    id INT AUTO_INCREMENT PRIMARY KEY,  
    employee_id VARCHAR(255),  
    call_time DATETIME,  
    notes TEXT  
);  

CREATE TABLE gps_locations (  
    id INT AUTO_INCREMENT PRIMARY KEY,  
    employee_id VARCHAR(255),  
    latitude DOUBLE,  
    longitude DOUBLE,  
    timestamp DATETIME  
);  
Build and Run the App
Connect your device or emulator and execute:

bash
Copy code
flutter run  
📦 Building the APK
Generate APK:

bash
Copy code
flutter build apk --release  
The APK will be saved in build/app/outputs/flutter-apk/app-release.apk.

Upload APK to GitHub:

Navigate to Releases in your GitHub repository.
Click Draft a new release.
Add a tag (e.g., v1.0.0) and title (e.g., Initial Release).
Attach the app-release.apk file.
Click Publish Release.
💡 Contributing
We appreciate contributions! Feel free to fork the repository, open an issue, or submit a pull request for improvements and new features.
