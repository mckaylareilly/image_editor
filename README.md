# Image Editor

**Image Editor** is a web-based application that allows users to upload, process, and edit images using Adobe Firefly's API. The app is built using **Ruby on Rails**, **React**, and **Adobe Spectrum Styling**, with **Active Storage** handling image uploads.

## Features

-  **Ruby on Rails (8.0.1)** – Backend API for image uploads and processing  
-  **React (with Vite)** – Fast and responsive frontend  
-  **Adobe Spectrum Styling** – Clean and accessible UI  
-  **Active Storage** – Secure image storage and retrieval  
-  **Firefly API Integration** – AI-powered image manipulation  

##  Installation & Setup

###  Prerequisites

Ensure you have the following installed:

- **Ruby** `3.4.2`
- **Rails** `8.0.1`
- **Node.js** `23.7.0`
- **npm** (included with Node)

### Backend Setup (Rails API)
Install Ruby 3.4.2 and install Rails 8.0.1
```sh
cd image_editor_backend
bundle install
rails db:setup
rails db:migrate
rails s
```
The Rails server will run at http://localhost:3000

### Frontend Setup (React UI)
Install Node v23.7.0
```sh
cd image-editor-frontend
npm install
npm run dev
```
