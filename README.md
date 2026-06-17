# Bravo Restaurante

Aplicativo Flutter para controle de consumo do restaurante e bar do projeto Bravo. O app centraliza o login do usuário, consulta reservas abertas, registra pedidos de restaurante, lança bebidas na conta do hóspede, acompanha o consumo e permite fechar a conta com geração de relatório.

## Tecnologias utilizadas

- Flutter
- Dart
- Provider para gerenciamento de estado
- Supabase como backend e banco de dados
- PDF e Printing para geração/impressão de relatórios
- Material Design para os componentes visuais

## Funcionalidades principais

- Login de usuário.
- Listagem de reservas abertas.
- Registro de pedidos do restaurante.
- Inclusão, edição e cancelamento de itens antes da confirmação do pedido.
- Lançamento de bebidas diretamente na conta do hóspede.
- Consulta da conta do hóspede.
- Fechamento da conta de consumo.
- Geração de relatório da conta.

## Estrutura do projeto

```text
lib/
  main.dart                 # Inicialização do app, Supabase, tema e Providers
  models/                   # Classes que representam os dados do banco
  mvvm/                     # ViewModels com regras de tela e chamadas ao Supabase
  pages/                    # Telas principais do aplicativo
  widgets/                  # Componentes reutilizáveis da interface

assets/
  LogoBravo.png             # Logo utilizada pelo app

android/                    # Configurações da versão Android
ios/                        # Configurações da versão iOS
web/                        # Estrutura para execução no navegador
```

## Organização do código

O projeto segue uma organização padrão MVVM:

- `models`: representam as entidades usadas pelo app, como usuário, reserva, produto, pedido, item de pedido e conta de consumo.
- `mvvm`: concentra os ViewModels, responsáveis por buscar dados, validar operações e notificar as telas quando o estado muda.
- `pages`: contém as telas completas, como login, home, registro de pedido, lançamento de bebida, conta do hóspede e fechamento de conta.
- `widgets`: guarda componentes reutilizáveis, como botões, cards, dropdowns, rótulos de formulário, seletor de quantidade e cores do app.

## Fluxo geral do app

1. O app inicia em `lib/main.dart`.
2. O Supabase é inicializado antes da interface ser exibida.
3. Os ViewModels são registrados com `MultiProvider`.
4. A primeira tela aberta é a tela de login.
5. Após o login, o usuário acessa a Home.
6. Pela Home, é possível navegar para pedidos, bebidas, conta do hóspede e fechamento de conta.

## Configuração do ambiente

Antes de executar o projeto, tenha instalado:

- Flutter SDK compatível com o SDK Dart informado no `pubspec.yaml`.
- Android Studio ou Android SDK configurado.
- JDK 17 ou superior para build Android.

No VS Code, este projeto pode usar o JBR do Android Studio como Java do Gradle:

```text
C:\Program Files\Android\Android Studio\jbr
```

## Como executar

No terminal, dentro da pasta raiz do projeto:

```powershell
cd C:\Users\pytag\projetos\flutter\bravo_restaurante
flutter pub get
flutter run
```

Para executar no navegador, quando disponível:

```powershell
flutter run -d chrome
```

## Backend

A conexão com o Supabase é inicializada em `lib/main.dart`. Os ViewModels usam essa conexão para consultar e gravar os dados necessários para as telas.

O app trabalha principalmente com dados de:

- Usuários
- Reservas
- Produtos
- Pedidos
- Itens de pedido
- Contas de consumo
- Bebidas lançadas na conta

## Relatórios

A geração de relatório da conta utiliza as dependências `pdf` e `printing`, declaradas no `pubspec.yaml`. A tela de fechamento de conta reúne os dados de consumo antes de gerar o documento.

## Observações

- A chave anon do Supabase é uma chave pública do cliente, mas as regras de segurança devem são controladas no próprio Supabase com RLS e políticas adequadas.
- Arquivos dentro de `build/` são gerados automaticamente e não devem ser editados manualmente.
- O arquivo `web/index.html` é apenas a estrutura de inicialização do Flutter Web; a interface real do app está nos arquivos Dart dentro de `lib/`.
