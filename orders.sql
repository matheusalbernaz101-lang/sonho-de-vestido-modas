-- Sonho de Vestido Modas: pedidos reais (sem cobrança online)
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  customer_name text not null,
  customer_phone text not null,
  fulfillment text not null check (fulfillment in ('delivery','pickup')),
  address text,
  payment_method text not null check (payment_method in ('pix','card','cash')),
  items jsonb not null,
  total numeric(12,2) not null check (total >= 0),
  status text not null default 'recebido'
    check (status in ('recebido','confirmado','preparando','pronto','enviado','entregue','cancelado')),
  created_at timestamptz not null default now()
);

alter table public.orders enable row level security;
drop policy if exists "Customers read own orders or admins" on public.orders;
create policy "Customers read own orders or admins"
on public.orders for select to authenticated
using (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "Admins update orders" on public.orders;
create policy "Admins update orders"
on public.orders for update to authenticated
using ((select public.is_admin()))
with check ((select public.is_admin()));

create or replace function public.create_store_order(
  p_customer_name text,
  p_customer_phone text,
  p_fulfillment text,
  p_address text,
  p_payment_method text,
  p_items jsonb
) returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_order_id uuid;
  v_items jsonb;
  v_total numeric(12,2);
begin
  if v_user_id is null then raise exception 'Entre na sua conta para salvar o pedido.'; end if;
  if length(trim(coalesce(p_customer_name,''))) < 2 then raise exception 'Informe seu nome.'; end if;
  if length(trim(coalesce(p_customer_phone,''))) < 8 then raise exception 'Informe um WhatsApp válido.'; end if;
  if p_fulfillment not in ('delivery','pickup') then raise exception 'Forma de recebimento inválida.'; end if;
  if p_fulfillment = 'delivery' and length(trim(coalesce(p_address,''))) < 5 then raise exception 'Informe o endereço de entrega.'; end if;
  if p_payment_method not in ('pix','card','cash') then raise exception 'Forma de pagamento inválida.'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then raise exception 'A sacola está vazia.'; end if;

  with requested as (
    select (x->>'id')::uuid as product_id, (x->>'quantity')::integer as quantity
    from jsonb_array_elements(p_items) x
  ), valid as (
    select p.id, p.name, p.price, r.quantity, p.sizes
    from requested r join public.products p on p.id = r.product_id
    where p.is_active = true and r.quantity between 1 and 50 and p.price is not null
  )
  select jsonb_agg(jsonb_build_object(
      'id', id, 'name', name, 'price', price, 'quantity', quantity, 'sizes', sizes
    )), sum(price * quantity)
  into v_items, v_total
  from valid;

  if v_items is null or jsonb_array_length(v_items) <> jsonb_array_length(p_items) then
    raise exception 'Um ou mais produtos não estão disponíveis. Atualize a sacola.';
  end if;

  insert into public.orders(user_id, customer_name, customer_phone, fulfillment, address, payment_method, items, total)
  values (v_user_id, trim(p_customer_name), trim(p_customer_phone), p_fulfillment,
    case when p_fulfillment='delivery' then trim(p_address) else null end,
    p_payment_method, v_items, v_total)
  returning id into v_order_id;

  return v_order_id;
end;
$$;

revoke all on function public.create_store_order(text,text,text,text,text,jsonb) from public;
grant execute on function public.create_store_order(text,text,text,text,text,jsonb) to authenticated;
grant select on public.orders to authenticated;
grant update(status) on public.orders to authenticated;
