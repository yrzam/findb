# FinDB - personal financial data model & tools


## About

This repository contains the SQLite schema and scripts to handle financial data. It takes a generic approach to assets, transactions, balances and other things providing heavy automation capabilities, extensibility & deep analysis opportunities.


### Why SQLite but not spreadsheets?

* **Schema**. Spreadsheets are terrible. They're made for structured data although it is nearly impossible to structure data in them. A spreadsheet is literally a set of cells with their own rules, no decent data validation mechanisms, no entity relationship, and schema is stored entirely in the user's mind.

* **Interface.** You can easily render graphs on HTML pages. "DB Browser for SQLite" can be used to edit data. SQL is very convenient for analytical/bulk update purposes, for scripting such as automatic data import. Queries & DDL have great readability. And you may find other ways to interact with the database.

* **Performance, limitations, control.** This project can handle millions of rows, while it's simply impossible to store them in Excel. Indexes are a basic thing for a database. The user has wider control over query execution.

* **Portability.** SQLite runs everywhere, it's fast, lightweight, free, secure and does not need an internet connection.

### What to start with?
`fin_transactions` and `balances` are core tables that need regular updates. They will lead you to other important things. For convenience, see the views.


## Schema

Below you can find the short summary with usage notes for each table. Only columns that need clarification are described. For the complete structure please see [DDL](./schema.sql).


### fin_assets (table)

A **Financial asset** is something you can track a balance of. It should be fungible and tradable.

```
is_base - defines whether this is a main unit of measure of your portfolio. Exactly one row must have this set to true
...
```

> Example: US Dollar. 


### fin_asset_types (table)

A **type of financial asset** (also known as an asset class) describes the nature of the financial assets.

**The number of records should not exceed 8 due to presentation reasons.**

> Examples: fiat currency, equity, bond, etc.   


### fin_storages (table)

**Financial storage** represents a place where assets are kept.

> Examples: savings account at a specific bank or broker, bag at home, cryptocurrency wallet.


### fin_assets_storages (table)

Join table. Financial storage can hold many assets, and an asset can be held in many storages.

```
allocation_group_id - shows which allocation group does a specific asset stored in specific storage belong to 
priority - used for sorting balances view and possibly other things 
...
```

### fin_asset_rates (table)

Stores historical exchange rates of financial assets.

```
rate = [asset_id value] / [base asset from fin_assets value] at [date]
...
```

**Rates should be up-to-date on the last day of each month.**


### current_fin_asset_rates (editable view)

Shows current exchange rates. Inactive assets are skipped. If you modify something, a new rate will be saved with a `date` of the current day.

> edit operations: update, insert

```
{asset_type, asset} - lookup tuple
rate - value
other columns - ignored
```


### fin_transactions (table)

Stores historical transactions. Transaction is an action that leads to a balance change in exactly one place.

Exchanges and self-transfers should be represented by two transactions, both having `is_rebalance` flag in the category. As for now, these two are not linked together due to  the homogenous nature of the financial assets.

```
asset_storage_id - points to storage and asset that took part in in transaction, direction is determined by the sign of [amount] 
amount - numeric, can be negative
reason_fin_asset_storage_id - (optional) financial asset, due to which transaction has occurred. This must be not manipulation with the asset itself, but the byproduct of its ownership
reason_phys_asset_id - (optional) physical asset, due to which transaction has occurred. This must be not manipulation with the asset itself, but the byproduct of its ownership
...
```

**Transactions should be up-to-date on the last day of each month, as they are matched with balances. For the initial data import, please create pseudo transactions of a category that has a flag `is_initial_import`. Transactions can be grouped into large blocks that are consistent with the overall balance delta.**


### fin_transaction_categories (table)

A **transaction category** describes the logical sense of the transaction.

Transaction categories must form a hierarchy with only one root. If a certain flag (starting with `is_`) is set to true on a category, it must be set to true on all of its child categories. The integrity is ensured via triggers that throw exceptions.

```
is_passive - whether the income or expense is passive (see definition below)
is_rebalance - whether the transaction is a part of self-transfer / exchange
is_initial_import - whether the transaction is an upload of the existing assets for accounting (thus it is neither active nor passive income/expense)
parent_id - reference to a category that is a superset of the current one 
min_view_depth - in the flattened representation, category shall not appear on a level lower than N, N>=0. Parent category takes multiple levels instead
...
```

Income or expense is considered passive if two conditions are met:

1. It occurred because of some ownership title of which did not change because of the current transaction.
2.	* For gains, there are no severe non-monetary losses associated with the transaction reason.
	* For losses, there are no severe non-monetary gains associated with the transaction reason. 

> For example, paying tax for the property a person lives in is not a passive loss, although paying it for a property that they lend is a passive loss.

> Examples of transaction categories: expense, salary transfer, rent payment, self transfer or exchange, dividends payout. 


### latest_fin_transactions (editable view)

Shows the latest transactions.

All fields except for pseudo-id are editable. There is also one special column `adjust_balance` - it allows to auto-update `balances` with the amount of the current transaction. It must be set explicitly during any operation (`insert` or `update`) that you want to affect balances. An error will be thrown if transaction's date is not the current date. **Please be cautious: while this option is convenient, used wrongly it may mess up your balance. Verify balances.**

> edit operations: update, insert, delete

```
{pseudo_id} - lookup tuple
amount, date, category, reason_phys_asset - values
{asset_type, asset_code, storage}, {reason_fin_asset_type, reason_fin_asset_code, reason_fin_asset_storage} - value tuples
adjust_balance - pseudo-column, if set to true current operation will be auto-reflected in balances. Works only with transactions of the current day
other columns - ignored
```


### balances (table)

Stores historical balances.

**Balances should be up-to-date on the last day of each month, as they are matched with transactions and rates.**


### current_balances (editable view)

Shows current financial balances. Inactive assets and storages are skipped.

If you edit `balance`, a supplied one will be saved with a date of the current day. Upon the insertion of a new row, a record in `fin_assets_storages` is created if needed and the balance is upserted.

> edit operations: update, insert

```
{asset_type, asset_code, storage} - lookup tuple
balance - value
other columns - ignored
``` 


### balance_goals (table)

Financial planning begins there. A **balance goal** is a plan to have a certain amount of financial assets on a balance for the specific purpose in the future, or keep it there constantly.

It is possible to have multiple goals per asset & storage - to complete all of them balance must be equal to or greater than sum of individual goals. Their progress is counted one by one according to the `priority`.

```
deadline - shows last desired date of completion
result_transaction_id - if saving resulted in the transaction, that transaction can be linked here. Such a goal will be considered complete
...
```

Cancelled goals should be deleted.


### current_balance_goals (view)

View that shows statuses of all goals (amount left, whether goal is accomplished, etc.). 

Goals that result in financial transactions are hidden. Goal is considered accomplished if there are enough corresponding assets on the balance. It is reversible, thus needs your attention. Accomplished goals are listed at the bottom of the view.


### phys_assets (table)

Represents real-world assets, purchases and other non-fungible (non-interchangeable) things that a person owns. The intended use case is to track large and important assets, especially ones that generate passive gains and losses.

The asset is considered currently owned if it is neither sold (`sell_transaction_id is null`) nor naturally expired (`is_expired=0`).

> Examples: house, apartment rented for a year, commercial property, car, blockchain NFT


### fin_allocation_groups (table)

This table sets a goal for the financial asset distribution.

Each asset & storage (`fin_assets_storages`) from your portfolio can reference a specific allocation group.

```
target share - a desired fraction of all your assets that the group should take. This may be any non-negative number
...
```

This table is not historical.

> Examples: allocation group "CASH" should have a 5% target share


### current_fin_allocation (view)

Shows current asset allocation calculated based on your balance and exchange rates. Both current and target shares are displayed.


### historical_monthly_txs_balances_mismatch (view)

Allows to keep balances consistent with transactions for the analytical purposes.

This view contains a row only if there is a mismatch between transaction delta and balance delta during the last 2 years. It is advised to keep this view empty via adding missing transactions or adjusting balances on a monthly basis.


### historical_monthly_balances (view)

Shows monthly balance with source, calculates deltas - total and grouped by asset type.

Data is calculated over the last 10 years with a period of 1 month for the last day of that month.

```
base_balance - total balance, converted to the base asset
base_balance_delta - balance change since the previous month
base_active_delta - delta (gains - losses) for all transactions that are not passive income/expenses and occurred during this month
base_passive_delta - balance change caused by exchange rate fluctuations, rebalancing, passive income/expenses, non-specified transactions
*_by_type - same data but per asset type, represented as a concatenated string
...
``` 


## Schema conventions

### Structure
* Schema shall be described in pure DDL. No initial tuples are allowed.
* Each table has an `id` column as a primary key, stated as `INTEGER AUTOINCREMENT`.
* Boolean is `INTEGER` 1 or 0, date is `NUMERIC`.
* Enforce unique in constraints, not indexes.
* Editable views have a `pseudo_id` column with unique non-null values so that client software can identify which row is being edited.

### Performance
* Expect gigabytes of data, do tricks such as force materializing.
* Do not use a view as a part of another view.
* The primary query is `SELECT`, so it makes sense to create many indexes.
* Always index foreign keys, remove indexes that are part of other covering indexes.
* Rely on internal indexes produced by primary keys and `UNIQUE` constraint

### Naming
* Snake case for identifiers, no prefixes except for indexes.
* Index name must be `i_[table_name]_[column names joined by "_"]`.
* The last noun in the table name is pluralized.
* Many-to-many (join) tables are named with a combination of tables they join. Although if referred tables have the same name prefix, it shall be used once. The table that usually has more records comes first.
> fin_assets + fin_storages => fin_assets_storages 
* Foreign key column names must end with `_id` and should point to the primary key. Their names must meet the table context and usually do not need extra database-wide prefixing.
* Names of the columns that store boolean must start with `is_`

### Common names
* `code` - string identifier that is required, unique in some way per table and contains no spaces. `code` is a static thing used to identify rows upon data edit.
* `name` - identifier just for the display purposes, that can be edited anytime
* `priority` - unique `INTEGER` value for sorting and other purposes
* `is_active` - used to hide non-needed entries from the current representation, keeping them as historical data  
