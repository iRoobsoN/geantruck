# GeanTruck 🚚

![Status](https://img.shields.io/badge/status-em%20desenvolvimento-yellow)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![License](https://img.shields.io/badge/license-MIT-green)

Um aplicativo completo para caminhoneiros gerenciarem as despesas de seus veículos, incluindo manutenções, abastecimentos e outros custos, com relatórios mensais em PDF.

---

## ✨ Funcionalidades

-   ✅ **Autenticação Segura**: Login de usuários utilizando Firebase Authentication.
-   🚚 **Gerenciamento de Frota**: Cadastre e gerencie múltiplos caminhões.
-   📝 **Registro de Atividades**:
    -   Registre manutenções detalhadas.
    -   Anote todos os abastecimentos.
    -   Controle despesas diversas.
-   📊 **Estatísticas e Relatórios**:
    -   Visualize um dashboard com as despesas do mês.
    -   Exporte relatórios mensais consolidados em formato **PDF**.
-   ☁️ **Sincronização na Nuvem**: Todos os dados são salvos de forma segura no Cloud Firestore.

---

## 🛠️ Tecnologias Utilizadas

Este projeto foi construído utilizando as seguintes tecnologias:

-   **[Flutter](https://flutter.dev/)**: Framework para desenvolvimento de apps multiplataforma.
-   **[Firebase](https://firebase.google.com/)**:
    -   **Authentication**: Para gerenciamento de usuários.
    -   **Cloud Firestore**: Como banco de dados NoSQL para armazenar os dados.
    -   **Hosting**: Para fazer o deploy da versão web.
-   **[Provider](https://pub.dev/packages/provider)**: Para gerenciamento de estado.
-   **[pdf](https://pub.dev/packages/pdf) / [printing](https://pub.dev/packages/printing)**: Para a criação e visualização dos relatórios em PDF.
-   **[intl](https://pub.dev/packages/intl)**: Para formatação de datas e moedas.

---

## 🚀 Começando

Siga os passos abaixo para configurar e executar o projeto em sua máquina local.

### **Pré-requisitos**

-   Ter o [Flutter](https://flutter.dev/docs/get-started/install) instalado.
-   Ter uma conta no [Firebase](https://console.firebase.google.com/).
-   Ter a [Firebase CLI](https://firebase.google.com/docs/cli) instalada: `npm install -g firebase-tools`.
-   Ter a [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup?platform=cli) instalada: `dart pub global activate flutterfire_cli`.

### **Instalação e Configuração**

1.  **Clone o repositório:**
    ```sh
    git clone https://github.com/iRoobsoN/geantruck.git
    cd geantruck
    ```

2.  **Instale as dependências do Flutter:**
    ```sh
    flutter pub get
    ```

3.  **Configure o Firebase:**
    -   Crie um novo projeto no [console do Firebase](https://console.firebase.google.com/).
    -   Execute o comando abaixo e selecione o projeto que você criou:
        ```sh
        flutterfire configure
        ```
    -   No console do Firebase, habilite os seguintes serviços:
        -   **Authentication**: Vá para a aba "Sign-in method" e ative a opção **Email/Password**.
        -   **Firestore Database**: Crie um novo banco de dados e, na aba "Rules", altere para permitir leitura e escrita por usuários autenticados:
          ```json
          rules_version = '2';
          service cloud.firestore {
            match /databases/{database}/documents {
              match /users/{userId}/{document=**} {
                allow read, write: if request.auth != null && request.auth.uid == userId;
              }
            }
          }
          ```

---

## 🏃‍♂️ Executando o Aplicativo

-   **Para executar em modo de desenvolvimento:**
    ```sh
    flutter run
    ```
    (Selecione o dispositivo desejado: Android, iOS, Chrome, etc.)

-   **Para compilar (build) para uma plataforma específica:**
    ```sh
    # Para a Web
    flutter build web

    # Para Android
    flutter build apk

    # Para iOS
    flutter build ios
    ```

---

## 🌐 Deploy da Versão Web

A versão web pode ser implantada no Firebase Hosting.

1.  **Construa a versão web:**
    ```sh
    flutter build web
    ```

2.  **Faça o deploy:**
    ```sh
    firebase deploy --only hosting
    ```

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.
