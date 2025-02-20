# OverLays - Gerenciador de Processos

Um sistema de gerenciamento de processos desenvolvido em Flutter que simula a execução e monitoramento de processos principais e seus processos secundários associados.
(Overlays)

## Funcionalidades

### Processos em Andamento
- **Processos Principais**
  - Criação de novos processos com nome e tamanho personalizado
  - Barra de progresso em tempo real
  - Exclusão de processos e seus secundários associados
  - Conclusão automática após finalização de todos os processos secundários

- **Processos Secundários**
  - Geração automática de 7 a 12 processos secundários para cada processo principal
  - Tamanho aleatório entre 30KB e metade do tamanho do processo principal
  - Progresso independente do processo principal
  - Barra de progresso em tempo real

### Processos Concluídos
- **Processos Principais Concluídos**
  - Visualização dos processos principais finalizados
  - Histórico de processos completos

- **Processos Secundários Concluídos**
  - Visualização dos processos secundários finalizados
  - Rastreamento por processo principal associado

## Regras de Negócio
- Processos secundários podem ser concluídos independentemente
- Processos principais só são concluídos após todos os seus processos secundários serem finalizados
- Cada processo tem sua própria velocidade de progressão
- Sistema de nomeação automática para processos secundários

## Requisitos Técnicos
- Flutter SDK
- Dart SDK
- Provider (para gerenciamento de estado)

## Estrutura do Projeto
```
lib/
├── models/
│   └── process.dart
├── pages/
│   ├── dashboard.dart
│   ├── completed_processes.dart
│   └── home_page.dart
├── services/
│   └── process_manager.dart
└── main.dart
```
