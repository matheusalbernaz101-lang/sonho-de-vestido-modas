# Sonho de Vestido Modas

Site estático em HTML, CSS e JavaScript conectado ao Supabase.

## Funcionalidades
- Catálogo público de vestidos ativos.
- Cadastro e login por e-mail.
- Novos perfis começam pendentes de aprovação.
- Painel de administração para aprovar, rejeitar ou bloquear contas.
- Cadastro, edição, publicação, ocultação e exclusão de vestidos.
- Upload de fotos no bucket `product-images`.
- WhatsApp e Instagram da loja.

## Configuração Supabase
O arquivo config.js contém apenas a URL do projeto e a Publishable key, que é pública por definição. Nunca coloque Secret key ou service_role no navegador.

O site depende das tabelas public.profiles e public.products, do bucket product-images e das funções/policies RLS criadas no projeto Supabase. Antes de divulgar, teste cadastro, login, aprovação, upload e as permissões de leitura e escrita.

WhatsApp: +55 16 99997-5202
Instagram: @sonho_de_vestido_modas
