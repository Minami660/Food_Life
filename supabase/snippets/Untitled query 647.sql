alter table food enable row level security;

create policy "Allow all"
on food
for all
using (true)
with check (true);

create table food (
  id serial primary key,
  name varchar(100) not null,
  category varchar(50) not null,
  expiry_date date not null,
  is_consumed boolean default false,
  note text,
  created_at timestamp default now()
);