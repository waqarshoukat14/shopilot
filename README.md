# shop_pilot

Shopilot is a Flutter-based shop management application designed vendors and businesses.

The goal of Shopilot is to make everyday shop management simple, fast, and accessible, with AI voice assistance as a major part of the experience.

Instead of spending time navigating multiple screens and entering information manually, vendors can use voice commands to perform common shop operations.

---

## 🚀 Features

### 🧾 Invoice Management
- Create invoices quickly
- Add products to invoices
- Track sold items
- Manage pending payments
- View invoice details

### 📦 Product & Inventory Management
- Add new products
- Update product information
- Track available stock
- Track sold quantities
- Identify low-stock products

### 👥 Customer Management
- Add customers
- Store customer information
- Track customer purchases
- Track pending payments

### 📊 Reports & Business Insights
Shopilot provides useful information such as:

- Today's sales
- Today's profit
- Pending payments
- Low-stock products
- Sales activity
- Product performance

### 🎙️ AI Voice Assistant

AI voice interaction is one of the main features of Shopilot.

Vendors can use their voice to perform shop-management tasks instead of manually entering information.

Examples:

> "Add 10 Coca Cola bottles."

> "Create an invoice for Ahmed."

> "How many products are left?"

> "Show me today's sales."

> "Which products are low in stock?"

The goal is to make Shopilot faster and easier to use for vendors who don't want to spend time navigating complex interfaces.

### 🌍 Multi-Language Voice Support

Shopilot is designed to support multiple languages for voice interaction:

- 🇬🇧 English
- 🇵🇰 Urdu
- 🇸🇦 Arabic
- 🇪🇸 Spanish
- 🇫🇷 French
- 🇮🇳 Hindi

---

## 🛠️ Tech Stack

### Frontend
- Flutter
- Dart
- Riverpod

### Backend & Services
- Firebase
- REST APIs
- FastAPI *(development/backend experimentation)*

### AI
- AI-powered voice interaction
- Natural language processing
- Voice-to-command workflows

---

## 🏗️ Application Architecture

Shopilot follows a modular architecture designed to keep the application scalable and maintainable.

Main areas include:

```text
Shopilot
│
├── Authentication
│
├── Dashboard
│
├── Products
│   ├── Add Product
│   ├── Edit Product
│   └── Inventory
│
├── Customers
│
├── Invoices
│
├── Reports
│
└── AI Voice Assistant
    ├── Voice Input
    ├── Command Processing
    └── Action Execution

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
