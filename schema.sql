CREATE TABLE IF NOT EXISTS "fin_storages" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"is_active"	INTEGER NOT NULL DEFAULT 1,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "fin_asset_types" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "fin_asset_rates" (
	"id"	INTEGER NOT NULL,
	"date"	NUMERIC NOT NULL,
	"asset_id"	INTEGER NOT NULL,
	"rate"	NUMERIC NOT NULL,
	UNIQUE("date","asset_id"),
	PRIMARY KEY("id"),
	FOREIGN KEY("asset_id") REFERENCES "fin_assets"("id")
);
CREATE TABLE IF NOT EXISTS "balances" (
	"id"	INTEGER NOT NULL,
	"date"	NUMERIC NOT NULL,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	NUMERIC NOT NULL,
	UNIQUE("date","asset_storage_id"),
	FOREIGN KEY("asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "fin_allocation_groups" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"target_share"	NUMERIC NOT NULL DEFAULT 0, priority int,
	PRIMARY KEY("id")
);
CREATE INDEX "i_fin_asset_rates_asset_id_date" ON "fin_asset_rates" (
	"asset_id",
	"date"	DESC
);
CREATE INDEX "i_balances_asset_storage_id_date" ON "balances" (
	"asset_storage_id",
	"date"	DESC
);
CREATE TABLE IF NOT EXISTS "fin_assets_storages" (
	"id"	INTEGER NOT NULL,
	"asset_id"	INTEGER NOT NULL,
	"storage_id"	INTEGER NOT NULL,
	"priority"	INTEGER UNIQUE,
	"allocation_group_id"	INTEGER,
	FOREIGN KEY("asset_id") REFERENCES "fin_assets"("id"),
	FOREIGN KEY("allocation_group_id") REFERENCES "fin_allocation_groups"("id"),
	FOREIGN KEY("storage_id") REFERENCES "fin_storages"("id"),
	PRIMARY KEY("id"),
	UNIQUE("asset_id","storage_id")
);
CREATE INDEX "i_fin_assets_storages_asset_id" ON "fin_assets_storages" (
	"asset_id"
);
CREATE INDEX "i_fin_assets_storages_storage_id" ON "fin_assets_storages" (
	"storage_id"
);
CREATE INDEX "i_fin_assets_storages_allocation_group_id" ON "fin_assets_storages" (
	"allocation_group_id"
);
CREATE TABLE IF NOT EXISTS "fin_assets" (
	"id"	INTEGER NOT NULL,
	"code"	TEXT NOT NULL,
	"name"	TEXT,
	"type_id"	INTEGER NOT NULL,
	"is_base"	INTEGER NOT NULL DEFAULT 0,
	"is_active"	INTEGER NOT NULL DEFAULT 1,
	UNIQUE("type_id","code"),
	PRIMARY KEY("id"),
	FOREIGN KEY("type_id") REFERENCES "fin_asset_types"("id")
);
CREATE INDEX "i_fin_assets_is_base" ON "fin_assets" (
	"is_base"
);
CREATE INDEX "i_fin_assets_type_id" ON "fin_assets" (
	"type_id"
);
CREATE VIEW "current_fin_asset_rates" as
select
	fa.id as pseudo_id,
	fat.name as asset_type,
	fa.code as asset,
	(select rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1) as rate,
	(select fa2.code from fin_assets fa2 where fa2.is_base=1 limit 1) as base_asset
from
	fin_assets fa
	join fin_asset_types fat on fat.id=fa.type_id
where
	fa.is_active=1
/* current_fin_asset_rates(pseudo_id,asset_type,asset,rate,base_asset) */;
CREATE TRIGGER current_fin_asset_rates_update
instead of update of rate on current_fin_asset_rates
begin
	insert into fin_asset_rates (asset_id, date, rate)
	values(
		(
			select
				fa.id
			from 
				fin_assets fa
				join fin_asset_types fat on fat.id=fa.type_id
			where
				fa.code=new.asset and
				fat.name=new.asset_type
		),
		date('now'),
		new.rate
	)
	on conflict(asset_id,date) do update 
	set rate=new.rate;
end;
CREATE VIEW current_fin_allocation as 
select 
	t.name as "group",
	round(t.base_balance,2) as base_balance,
	(select code from fin_assets fa2 where fa2.is_base=1 limit 1) as base_asset,
	(round(t.current_share, 1) || '%') as current_share,
	(round(t.target_share, 1)  || '%') as target_share
from (
		select
			t.name,
			t.base_balance,
			t.base_balance*100 / sum(t.base_balance) over() as current_share,
			t.target_share,
			1 as sort1,
			t.priority
		from
			(
				select
					fag.name,
					fag.priority,
					coalesce(
						sum(
							(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1)*
							(select far.rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1)
						),
					0) as base_balance,
					fag.target_share * 100 / sum(fag.target_share) over () as target_share
				from
					fin_allocation_groups fag
					left join fin_assets_storages fas on fas.allocation_group_id=fag.id
					left join fin_assets fa on fa.id=fas.asset_id
					left join fin_storages fs on fs.id=fas.storage_id
				where
					fas.id is null or 
					(fa.is_active=1 and fs.is_active=1)
				group by 
					fag.id
			) t
	union all
		select
			'Others' as name,
			sum(
				(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1)*
				(select far.rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1)
			) as base_balance,
			null as current_share,
			null as target_share,
			0 as sort1,
			null as priority
		from
			fin_assets_storages fas
			join fin_assets fa on fa.id=fas.asset_id
			join fin_storages fs on fs.id=fas.storage_id
		where
			fas.allocation_group_id is null and
			fa.is_active=1 and
			fs.is_active=1
) t
where
	t.base_balance!=0 or t.target_share!=0
order by
	sort1 desc, priority desc
/* current_fin_allocation("group",base_balance,base_asset,current_share,target_share) */;
CREATE VIEW "current_balances" AS select
	*
from (
	select
		fas.id as pseudo_id,
		fat.name as asset_type,
		coalesce(fa.code,fa.name) as asset_name,
		fs.name  as storage,
		(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1) as balance,
		fa.code as asset_code,
		round(
			(select b.amount from balances b where b.asset_storage_id=fas.id order by b.date desc limit 1)*
			(select far.rate from fin_asset_rates far where far.asset_id=fa.id order by far.date desc limit 1),
		2) as base_balance,
		(select code from fin_assets fa2 where fa2.is_base=1 limit 1) as base_asset
	from
		fin_assets_storages fas
		join fin_assets fa on fa.id=fas.asset_id
		join fin_asset_types fat on fat.id=fa.type_id
		join fin_storages fs on fs.id=fas.storage_id
	where
		fa.is_active=1 and
		fs.is_active=1
	order by
		fas.priority desc
) t
where 
	t.balance is not null
/* current_balances(pseudo_id,asset_type,asset_name,storage,balance,asset_code,base_balance,base_asset) */;
CREATE TRIGGER current_balances_insert
instead of insert on current_balances
begin

	insert into fin_assets_storages(asset_id, storage_id)
	values(
		(select fa.id from fin_assets fa join fin_asset_types fat on fat.id=fa.type_id where fa.code=new.asset_code and fat.name=new.asset_type),
		(select id from fin_storages where name=new.storage)
	)
	on conflict do nothing;
	
	insert into balances(asset_storage_id, date, amount)
	values(
		(
			select
				fas.id
			from
				fin_assets_storages fas
				join fin_assets fa on fa.id=fas.asset_id
				join fin_asset_types fat on fat.id=fa.type_id
				join fin_storages fs on fs.id=fas.storage_id
			where
				fa.code = new.asset_code and
				fat.name = new.asset_type and
				fs.name = new.storage
		),
		date('now'),
		new.balance
	)
	on conflict(asset_storage_id, date) do update
	set 
		amount = new.balance;
		
end;
CREATE TRIGGER current_balances_update
instead of update of balance on current_balances
begin
	insert into balances(asset_storage_id, date, amount)
	values(
		(
			select
				fas.id
			from
				fin_assets_storages fas
				join fin_assets fa on fa.id=fas.asset_id
				join fin_asset_types fat on fat.id=fa.type_id
				join fin_storages fs on fs.id=fas.storage_id
			where
				fa.code = new.asset_code and
				fat.name = new.asset_type and
				fs.name = new.storage
		),
		date('now'),
		new.balance
	)
	on conflict(asset_storage_id, date) do update
	set 
		amount = new.balance;
end;
CREATE TABLE IF NOT EXISTS "fin_transactions" (
	"id"	INTEGER NOT NULL,
	"date"	NUMERIC NOT NULL,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	NUMERIC NOT NULL,
	"category_id"	INTEGER NOT NULL,
	"reason_fin_asset_storage_id"	INTEGER,
	"reason_phys_asset_id"	INTEGER,
	FOREIGN KEY("reason_fin_asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	FOREIGN KEY("category_id") REFERENCES "fin_transaction_categories"("id"),
	PRIMARY KEY("id"),
	FOREIGN KEY("reason_phys_asset_id") REFERENCES "phys_assets"("id")
);
CREATE INDEX "i_fin_transactions_asset_storage_id_date" ON "fin_transactions" (
	"asset_storage_id",
	"date"	DESC
);
CREATE INDEX "i_fin_transactions_result_fin_asset_storage_id" ON "fin_transactions" (
	"reason_fin_asset_storage_id"
);
CREATE INDEX "i_fin_transactions_category_id" ON "fin_transactions" (
	"category_id"
);
CREATE TABLE IF NOT EXISTS "phys_assets" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"buy_transaction_id"	INTEGER,
	"sell_transaction_id"	INTEGER,
	"is_expired"	INTEGER NOT NULL DEFAULT 0,
	FOREIGN KEY("buy_transaction_id") REFERENCES "fin_transactions"("id"),
	FOREIGN KEY("sell_transaction_id") REFERENCES "fin_transactions"("id"),
	PRIMARY KEY("id")
);
CREATE TABLE IF NOT EXISTS "balance_goals" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL,
	"asset_storage_id"	INTEGER NOT NULL,
	"amount"	NUMERIC NOT NULL,
	"priority"	INTEGER NOT NULL UNIQUE,
	"deadline"	NUMERIC,
	"result_transaction_id"	INTEGER,
	FOREIGN KEY("asset_storage_id") REFERENCES "fin_assets_storages"("id"),
	PRIMARY KEY("id"),
	FOREIGN KEY("result_transaction_id") REFERENCES "fin_transactions"("id")
);
CREATE INDEX "i_balance_goals_asset_storage_id" ON "balance_goals" (
	"asset_storage_id"
);
CREATE INDEX "i_balance_goals_result_phys_asset_id" ON "balance_goals" (
	"result_transaction_id"
);
CREATE INDEX "i_fin_transactions_result_phys_asset_id" ON "balance_goals" (
	"result_transaction_id"
);
CREATE VIEW "current_balance_goals" AS select
	t.amount_left=0 as is_accomplished,
	t.goal,
	t.storage,
	t.amount_total,
	t.amount_left,
	case when t.amount_left!=0 then t.deadline end as deadline
from (
	select
		bg.name as goal,
		coalesce(fa.name,fa.code)||' - '||fs.name as storage,
		bg.amount as amount_total,
		bg.priority,
		bg.deadline,
		min(max(
			sum(bg.amount) over(
				partition by
					bg.asset_storage_id
				order by
					bg.priority desc
				rows between 
					unbounded preceding and current row
			) - coalesce((
				select 
					amount
				from 
					balances b 
				where 
					b.asset_storage_id=bg.asset_storage_id
				order by
					b.date desc
				limit 1
			),0),
			0
		), bg.amount) as amount_left
	from
		balance_goals bg
		join fin_assets_storages fas on fas.id=bg.asset_storage_id
		join fin_assets fa on fa.id=fas.asset_id
		join fin_storages fs on fs.id=fas.storage_id
	where
		bg.result_transaction_id is null
) t
order by 
	is_accomplished asc,
	t.priority desc
/* current_balance_goals(is_accomplished,goal,storage,amount_total,amount_left,deadline) */;
CREATE VIEW historical_monthly_txs_balances_mismatch as
with recursive dates(mo_start_date, date) as (
		values(
			date('now', 'start of month'),
			date('now', 'start of month', '+1 month', '-1 day')
		)
	union all
		select
			date(mo_start_date, '-1 month'),
			date(mo_start_date, '-1 day')
		from
			dates
		where
			mo_start_date > (select min(date) from balances) or
			mo_start_date > (select min(date) from fin_transactions)
		limit 2*12 -- 2 years
),
constants as (
	select
		(select min(mo_start_date) from dates) as start_date
)

select 
	t.mo_start_date as start_date,
	t.date as end_date,
	fs.name as storage,
	t.balance_delta - t.tx_delta as amount_unaccounted,
	coalesce(fa.code,fa.name) as asset,
	t.tx_delta,
	t.balance_delta
from (
		select
			d.*,
			fas.asset_id as asset_id,
			fas.storage_id as storage_id,
			coalesce((select sum(amount) from fin_transactions ft where ft.asset_storage_id=fas.id and ft.date>=d.mo_start_date and ft.date<=d.date),0) as tx_delta,
			coalesce((
				select b.amount from balances b where b.asset_storage_id=fas.id and b.date<=d.date order by b.date desc limit 1
			),0) - coalesce((
				select coalesce(b.amount,0) from balances b where b.asset_storage_id=fas.id and b.date<d.mo_start_date order by b.date desc limit 1
			),0) as balance_delta
		from
			dates d
			cross join fin_assets_storages fas
	) t
	join fin_assets fa on fa.id=t.asset_id
	join fin_storages fs on fs.id=t.storage_id
where
	t.tx_delta!=t.balance_delta
order by
	t.date desc
/* historical_monthly_txs_balances_mismatch(start_date,end_date,storage,amount_unaccounted,asset,tx_delta,balance_delta) */;
CREATE TABLE IF NOT EXISTS "fin_transaction_categories" (
	"id"	INTEGER NOT NULL,
	"name"	TEXT NOT NULL UNIQUE,
	"is_rebalance"	INTEGER NOT NULL DEFAULT 0,
	"is_passive"	INTEGER NOT NULL DEFAULT 0,
	"is_initial_import"	INTEGER NOT NULL DEFAULT 0,
	PRIMARY KEY("id")
);
CREATE VIEW historical_monthly_balances as
with recursive dates(mo_start_date, date) as (
		values(
			date('now', 'start of month'),
			date('now', 'start of month', '+1 month', '-1 day')
		)
	union all
		select
			date(mo_start_date, '-1 month'),
			date(mo_start_date, '-1 day')
		from
			dates
		where
			mo_start_date > (select min(date) from balances)
		limit 10*12 -- use yearly view for periods over 10 years
),
constants as(
	select
		(select code from fin_assets fa2 where fa2.is_base=1 limit 1) as base_asset
),

data_by_type as materialized( -- force materialize - 2x faster due to lead()
select
	d.date,
	fat.id as asset_type_id,
	(
		select
			sum(
				(select b.amount from balances b where b.asset_storage_id=fas.id and b.date<=d.date order by b.date desc limit 1)*
				(select far.rate from fin_asset_rates far where far.asset_id=fas.asset_id and far.date<=d.date order by far.date desc limit 1)
			)
		from
			fin_assets fa
			join fin_assets_storages fas on fas.asset_id=fa.id
		where
			fa.type_id=fat.id 
	) as base_balance,
	(
		select
			coalesce(sum(
				(select sum(ft.amount) from fin_transactions ft join fin_transaction_categories ftc on ftc.id=ft.category_id where ft.asset_storage_id=fas.id and ft.date>=d.mo_start_date and ft.date<=d.date and ftc.is_rebalance=0 and ftc.is_passive=0 and ftc.is_initial_import=0)*
				(select far.rate from fin_asset_rates far where far.asset_id=fas.asset_id and far.date<=d.date order by far.date desc limit 1)
			),0)
		from
			fin_assets fa
			join fin_assets_storages fas on fas.asset_id=fa.id
		where
			fa.type_id=fat.id
	) as base_active_delta,
	(
		select
			coalesce(sum(
				(select sum(ft.amount) from fin_transactions ft join fin_transaction_categories ftc on ftc.id=ft.category_id where ft.asset_storage_id=fas.id and ft.date>=d.mo_start_date and ft.date<=d.date and ftc.is_initial_import=1)*
				(select far.rate from fin_asset_rates far where far.asset_id=fas.asset_id and far.date<=d.date order by far.date desc limit 1)
			),0)
		from
			fin_assets fa
			join fin_assets_storages fas on fas.asset_id=fa.id
		where
			fa.type_id=fat.id
	) as base_excluded_delta
from
	dates d
	cross join fin_asset_types fat
)

select
	t.date,
	round(sum(t.base_balance),2) as base_balance,
	round(sum(t.base_balance_delta),2) as base_balance_delta,
	round(sum(t.base_active_delta),2) as base_active_delta,
	round(sum(t.base_balance_delta)-sum(t.base_active_delta)-sum(t.base_excluded_delta),2) as base_passive_delta,
	(select base_asset from constants) as base_asset,
	group_concat(fat.name||'='||cast(t.base_balance as integer) || ' ' || (select base_asset from constants), ' ') as base_balance_by_type,
	group_concat(fat.name||'='||cast(t.base_balance_delta as integer) || ' ' || (select base_asset from constants), ' ') as base_balance_delta_by_type,
	group_concat(fat.name||'='||cast(t.base_active_delta as integer) || ' ' || (select base_asset from constants), ' ') as base_active_delta_by_type,
	group_concat(fat.name||'='||cast(t.base_balance_delta-t.base_active_delta-t.base_excluded_delta as integer) || ' ' || (select base_asset from constants), ' ') as base_passive_delta_by_type
from 
	(
		select
			t.*,
			t.base_balance-lead(t.base_balance) over(partition by t.asset_type_id order by date desc) as base_balance_delta
		from
			data_by_type t
		where 
			t.base_balance is not null
	) t
	join fin_asset_types fat on fat.id=t.asset_type_id
group by
	1
order by
	t.date desc
/* historical_monthly_balances(date,base_balance,base_balance_delta,base_active_delta,base_passive_delta,base_asset,base_balance_by_type,base_balance_delta_by_type,base_active_delta_by_type,base_passive_delta_by_type) */;
