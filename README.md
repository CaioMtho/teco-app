# TECO: Marketplace de Serviços de Suporte de Informática

## 🚀 Visão Geral do Projeto

O **TECO** é um marketplace inovador que conecta pessoas e empresas que buscam suporte técnico de informática (Requesters) a profissionais e empresas qualificados que oferecem esses serviços (Providers). A plataforma visa simplificar o processo de encontrar e contratar suporte técnico, garantindo transações seguras e comunicação eficiente.

### Principais Funcionalidades (MVP):

*   **Gestão de Perfis**: Cadastro e gerenciamento de perfis para Requesters e Providers.
*   **Criação e Gestão de Solicitações**: Requesters podem abrir e acompanhar solicitações de suporte.
*   **Envio e Aceite de Propostas**: Providers podem enviar propostas para solicitações, e Requesters podem aceitá-las.
*   **Chat em Tempo Real**: Comunicação direta entre Requesters e Providers após o aceite de uma proposta.
*   **Sistema de Pagamento em Custódia (Escrow)**: Pagamentos seguros que são liberados apenas após a confirmação do serviço.
*   **Avaliações e Feedback**: Sistema de avaliação mútua para garantir a qualidade dos serviços.
*   **Abertura de Disputas**: Mecanismo para resolução de conflitos.

## 🛠️ Tecnologias Utilizadas

O projeto TECO é construído com uma arquitetura moderna e escalável:

*   **Frontend**: [**Flutter**](https://flutter.dev/)
*   **Backend**: [**Supabase**](https://supabase.com/)
    *   **PostgreSQL**: Banco de dados relacional robusto.
    *   **Supabase Auth**: Autenticação de usuários (e-mail/senha, social, magic link).
    *   **Supabase Storage**: Armazenamento de arquivos (ex: avatares, evidências).
    *   **Supabase Realtime**: Sincronização de dados em tempo real (essencial para o chat).
    *   **Edge Functions (Deno)**: Funções serverless para lógica de negócio (ex: processamento de pagamentos, notificações).

## 🤝 Contribuição

Siga o [Guia de Contribuição](CONTRIBUTING.md) e o [Guia de Arquitetura](docs/architecture-guide.md) para informações de contribuição e estrutura do projeto.

## 📄 Licença

Veja o arquivo [LICENSE](LICENSE) para informações sobre Licensa.


