# Pokédex Flutter

Uma Pokédex responsiva desenvolvida em **Flutter**, com busca, filtros e informações detalhadas obtidas em tempo real pela [PokéAPI](https://pokeapi.co/). O projeto funciona no navegador, Android, iOS, Windows, macOS e Linux.

[![Flutter](https://img.shields.io/badge/Flutter-3.41%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.12%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![PokéAPI](https://img.shields.io/badge/API-Pok%C3%A9API-EF5350)](https://pokeapi.co/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ⚡ Teste o aplicativo

### [🔴 Abrir a Pokédex no navegador](https://patrickgusmao10.github.io/pokedex-flutter/)

> O link ficará disponível depois que este repositório for publicado como `pokedex-flutter` e o GitHub Pages for ativado. O deploy é automático pelo workflow incluído no projeto.

## Sobre o projeto

O aplicativo apresenta o catálogo completo de Pokémon em uma interface moderna e adaptável a diferentes tamanhos de tela. A integração não exige chave de API: os dados, sprites e informações de cada Pokémon são carregados diretamente da PokéAPI.

### Funcionalidades

- Listagem completa com carregamento progressivo por rolagem infinita;
- busca instantânea por nome ou número da Pokédex Nacional;
- filtros pelos 18 tipos de Pokémon;
- tela de detalhes com descrição em português e fallback para inglês;
- altura, peso, categoria, habitat e habilidades;
- atributos base com barras animadas;
- fraquezas e resistências calculadas a partir da combinação de tipos;
- cadeia evolutiva completa, inclusive evoluções ramificadas;
- paleta de cores dinâmica baseada no tipo de cada Pokémon;
- cache de imagens e requisições em memória;
- tratamento de falhas de conexão com opção de tentar novamente.

## Tecnologias

- Flutter e Dart;
- Material Design 3;
- PokéAPI;
- pacotes `http`, `cached_network_image` e `google_fonts`;
- GitHub Actions e GitHub Pages para publicação da versão web.

## Como executar do zero

### Pré-requisitos

1. Instale o [Flutter SDK](https://docs.flutter.dev/get-started/install) compatível com Dart 3.12 ou superior.
2. Confirme a instalação:

```bash
flutter doctor
```

### Instalação

```bash
git clone https://github.com/patrickgusmao10/pokedex-flutter.git
cd pokedex-flutter
flutter pub get
flutter run
```

O Flutter exibirá os dispositivos disponíveis. Para abrir diretamente no Chrome:

```bash
flutter run -d chrome
```

O projeto não utiliza arquivo `.env`, banco de dados ou chave de API. É necessário apenas estar conectado à internet durante o uso.

## Executar em uma plataforma específica

```bash
# Navegador
flutter run -d chrome

# Android (com emulador ou aparelho conectado)
flutter run -d android

# Windows
flutter run -d windows
```

Para listar os dispositivos reconhecidos:

```bash
flutter devices
```

## Qualidade do código

```bash
flutter analyze
```

## Estrutura principal

```text
lib/
├── main.dart
├── models/       # Modelos de Pokémon, atributos e evoluções
├── pages/        # Listagem e tela de detalhes
├── services/     # Integração e cache da PokéAPI
├── theme/        # Cores dos tipos e traduções
└── widgets/      # Componentes visuais reutilizáveis
```

## Publicação no GitHub Pages

O arquivo `.github/workflows/deploy-pages.yml` gera e publica a versão web automaticamente a cada alteração enviada para a branch `main`.

Na primeira publicação, abra **Settings → Pages** no repositório e, em **Build and deployment → Source**, selecione **GitHub Actions**. Depois que a ação terminar, o botão “Abrir a Pokédex” no início deste README apontará para o aplicativo.

Se usar outro nome de repositório, altere `REPOSITORY_NAME` no workflow e o endereço do botão acima.

## Autor

Desenvolvido por [Patrick Gusmão](https://github.com/patrickgusmao10).

## Licença e créditos

O código está disponível sob a [licença MIT](LICENSE).

Dados e sprites são fornecidos pela [PokéAPI](https://pokeapi.co/). Pokémon e os materiais relacionados são marcas de Nintendo, Game Freak e The Pokémon Company. Este é um projeto educacional de fã, não oficial e sem afiliação com essas empresas.
