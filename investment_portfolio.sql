-- ============================================================
--  INVESTMENT PORTFOLIO MANAGEMENT SYSTEM
--  CFG Data & MySQL Assignment - Topic Assignment 3
-- ============================================================

-- ------------------------------------------------------------
-- Scenario:
-- This project represents a simple investment portfolio management
-- system. It stores information about investors, their portfolios,
-- financial assets, transactions, supported currencies, and market prices.
-- The database can be used to review trading activity, compare asset
-- performance, and estimate portfolio profitability.
-- ------------------------------------------------------------


-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================

DROP DATABASE IF EXISTS investment_portfolio;
CREATE DATABASE investment_portfolio;
USE investment_portfolio;



-- ============================================================
-- SECTION 2: TABLE CREATION
-- ============================================================

-- ------------------------------------------------------------
-- Table: investors
-- Stores registered investor profiles.
-- risk_profile classifies each investor's appetite for risk.
-- ------------------------------------------------------------
CREATE TABLE investors (
    investor_id INT NOT NULL AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    country VARCHAR(50) NOT NULL,
    joined_date DATE NOT NULL, -- Date the investor joined the platform
    risk_profile ENUM('conservative', 'moderate', 'aggressive') NOT NULL DEFAULT 'moderate', -- Default risk level if none is provided
    CONSTRAINT pk_investors PRIMARY KEY (investor_id),
    CONSTRAINT uq_investor_email UNIQUE (email)
);


-- ------------------------------------------------------------
-- Table: currencies
-- Stores supported currencies and their USD exchange rates.
-- This table is referenced by both assets and portfolios,
-- ensuring no duplicate currency data (normalisation).
-- ------------------------------------------------------------
CREATE TABLE currencies (
    currency_code VARCHAR(3) NOT NULL,
    currency_name VARCHAR(50) NOT NULL,
    symbol VARCHAR(5) NOT NULL,
    usd_rate DECIMAL(10, 6) NOT NULL, -- USD value of 1 unit of this currency
    last_updated DATE NOT NULL, -- Date the exchange rate was last updated
    CONSTRAINT pk_currencies PRIMARY KEY (currency_code),
    CONSTRAINT chk_usd_rate CHECK (usd_rate > 0)
);


-- ------------------------------------------------------------
-- Table: portfolios
-- Stores investor portfolios in different base currencies.
-- Each portfolio belongs to one investor.
-- An investor may hold multiple portfolios with different base currencies
-- (e.g. a GBP ISA and a USD brokerage account).
-- ------------------------------------------------------------
CREATE TABLE portfolios (
    portfolio_id INT NOT NULL AUTO_INCREMENT,
    investor_id INT NOT NULL,
    portfolio_name VARCHAR(100) NOT NULL,
    base_currency_code VARCHAR(3) NOT NULL, -- Portfolio is valued in this currency
    created_date DATE NOT NULL, -- Date the portfolio was created
    CONSTRAINT pk_portfolios PRIMARY KEY (portfolio_id),
    CONSTRAINT fk_portfolios_investor
        FOREIGN KEY (investor_id) REFERENCES investors(investor_id),
    CONSTRAINT fk_portfolios_currency
        FOREIGN KEY (base_currency_code) REFERENCES currencies(currency_code)
);


-- ------------------------------------------------------------
-- Table: assets
-- Stores tradeable financial instruments.
-- asset_type distinguishes stocks, crypto, bonds, and forex.
-- Each asset is priced in a currency.
-- ------------------------------------------------------------
CREATE TABLE assets (
    asset_id INT NOT NULL AUTO_INCREMENT,
    ticker VARCHAR(10) NOT NULL,
    asset_name VARCHAR(100) NOT NULL,
    asset_type ENUM('stock', 'crypto', 'bond', 'forex') NOT NULL,
    currency_code VARCHAR(3) NOT NULL, -- Trading currency of the asset
    exchange VARCHAR(50) NOT NULL, -- Exchange or platform where the asset is traded
    current_price DECIMAL(15, 4) NOT NULL, -- Latest available market price
    CONSTRAINT pk_assets PRIMARY KEY (asset_id),
    CONSTRAINT uq_ticker UNIQUE (ticker),
    CONSTRAINT fk_assets_currency FOREIGN KEY (currency_code) REFERENCES currencies(currency_code),
    CONSTRAINT chk_current_price CHECK (current_price > 0)
);


-- ------------------------------------------------------------
-- Table: transactions
-- Records every buy/sell event within a portfolio.
-- total_value is stored explicitly for historical accuracy —
-- price may change later but the transaction value must not.
-- ------------------------------------------------------------
CREATE TABLE transactions (
    transaction_id INT NOT NULL AUTO_INCREMENT,
    portfolio_id INT NOT NULL,
    asset_id INT NOT NULL,
    transaction_type ENUM('buy', 'sell') NOT NULL,
    quantity DECIMAL(15, 6) NOT NULL, -- Decimal quantity supports fractional crypto purchases
    price_at_txn DECIMAL(15, 4) NOT NULL, -- Price locked at time of trade
    total_value DECIMAL(15, 4) NOT NULL, -- quantity * price_at_txn
    transaction_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, -- Automatically records when the transaction was entered
    notes VARCHAR(255), -- Optional note for corrections or transaction context
    CONSTRAINT pk_transactions PRIMARY KEY (transaction_id),
    CONSTRAINT fk_transactions_portfolio
        FOREIGN KEY (portfolio_id) REFERENCES portfolios(portfolio_id),
    CONSTRAINT fk_transactions_asset
        FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    CONSTRAINT chk_quantity CHECK (quantity > 0),
    CONSTRAINT chk_price_at_txn CHECK (price_at_txn > 0),
    CONSTRAINT chk_total_value CHECK (total_value > 0)
);


-- ------------------------------------------------------------
-- Table: market_prices
-- Daily OHLC (Open, High, Low, Close) price history per asset.
-- Separated from assets table to avoid repeating asset metadata
-- for every price point (normalisation).
-- ------------------------------------------------------------
CREATE TABLE market_prices (
    price_id INT NOT NULL AUTO_INCREMENT,
    asset_id INT NOT NULL,
    price_date DATE NOT NULL, -- Trading date for this price record
    open_price DECIMAL(15, 4) NOT NULL, -- Opening price for the day
    close_price DECIMAL(15, 4) NOT NULL, -- Closing price for the day
    high_price DECIMAL(15, 4) NOT NULL, -- Highest price reached during the day
    low_price DECIMAL(15, 4) NOT NULL, -- Lowest price reached during the day
    volume BIGINT, -- Daily traded volume; BIGINT supports very large market activity
    CONSTRAINT pk_market_prices PRIMARY KEY (price_id),
    CONSTRAINT fk_market_prices_asset FOREIGN KEY (asset_id) REFERENCES assets(asset_id),
    CONSTRAINT uq_asset_date UNIQUE (asset_id, price_date),  -- One row per asset per day
    CONSTRAINT chk_high_low CHECK (high_price >= low_price),
    CHECK (open_price > 0),
    CHECK (close_price > 0),
    CHECK (high_price > 0),
    CHECK (low_price > 0)
);


-- ============================================================
-- SECTION 3: INSERT MOCK DATA
-- ============================================================

-- ------------------------------------------------------------
-- Insert data into investors
-- ------------------------------------------------------------
INSERT INTO investors (first_name, last_name, email, country, joined_date, risk_profile)
VALUES
('Alice', 'Morgan', 'alice.morgan@email.com', 'UK', '2024-01-15', 'moderate'),
('James', 'Carter', 'james.carter@email.com', 'USA', '2024-02-10', 'aggressive'),
('Sophie', 'Turner', 'sophie.turner@email.com', 'Canada', '2024-03-05', 'conservative'),
('Daniel', 'Lee', 'daniel.lee@email.com', 'Singapore', '2024-03-20', 'moderate'),
('Maya', 'Patel', 'maya.patel@email.com', 'India', '2024-04-01', 'aggressive'),
('Oliver', 'Brown', 'oliver.brown@email.com', 'Australia', '2024-04-15', 'moderate'),
('Emma', 'Wilson', 'emma.wilson@email.com', 'Ireland', '2024-05-02', 'conservative'),
('Noah', 'Smith', 'noah.smith@email.com', 'Germany', '2024-05-18', 'aggressive');

-- ------------------------------------------------------------
-- Insert data into currencies
-- ------------------------------------------------------------
INSERT INTO currencies (currency_code, currency_name, symbol, usd_rate, last_updated)
VALUES
('USD', 'US Dollar', '$', 1.000000, '2026-04-10'),
('GBP', 'British Pound', '£', 1.270000, '2026-04-10'),
('EUR', 'Euro', '€', 1.090000, '2026-04-10'),
('JPY', 'Japanese Yen', '¥', 0.006700, '2026-04-10'),
('CHF', 'Swiss Franc', 'CHF', 1.110000, '2026-04-10'),
('CAD', 'Canadian Dollar', 'C$', 0.740000, '2026-04-10'),
('AUD', 'Australian Dollar', 'A$', 0.660000, '2026-04-10'),
('TRY', 'Turkish Lira', '₺', 0.031000, '2026-04-10');

-- ------------------------------------------------------------
-- Insert data into portfolios
-- ------------------------------------------------------------
INSERT INTO portfolios (investor_id, portfolio_name, base_currency_code, created_date)
VALUES
(1, 'Global Growth Fund', 'USD', '2024-01-20'),
(2, 'High Risk Alpha', 'USD', '2024-02-15'),
(3, 'Capital Preservation', 'GBP', '2024-03-10'),
(4, 'Asia Opportunity', 'USD', '2024-03-25'),
(5, 'Emerging Markets', 'EUR', '2024-04-05'),
(6, 'Balanced Wealth', 'AUD', '2024-04-20'),
(7, 'Retirement Shield', 'GBP', '2024-05-08'),
(8, 'Crypto Momentum', 'USD', '2024-05-25');

-- ------------------------------------------------------------
-- Insert data into assets
-- ------------------------------------------------------------
INSERT INTO assets (ticker, asset_name, asset_type, currency_code, exchange, current_price)
VALUES
('AAPL', 'Apple Inc.', 'stock', 'USD', 'NASDAQ', 189.4500),
('TSLA', 'Tesla Inc.', 'stock', 'USD', 'NASDAQ', 172.8800),
('BTC', 'Bitcoin', 'crypto', 'USD', 'Binance', 64250.0000),
('ETH', 'Ethereum', 'crypto', 'USD', 'Binance', 3150.5000),
('VOD', 'Vodafone Group', 'stock', 'GBP', 'LSE', 0.7100),
('BMW', 'BMW AG', 'stock', 'EUR', 'XETRA', 98.3500),
('JP10Y', 'Japan 10Y Bond', 'bond', 'JPY', 'TSE', 149.2200),
('EURUSD', 'Euro / US Dollar', 'forex', 'USD', 'Forex Market', 1.0845);

-- ------------------------------------------------------------
-- Insert data into transactions
-- ------------------------------------------------------------
INSERT INTO transactions (portfolio_id, asset_id, transaction_type, quantity, price_at_txn, total_value, transaction_date, notes)
VALUES
(1, 1, 'buy', 10.000000, 185.0000, 1850.0000, '2026-04-01 09:15:00', 'Initial Apple position'),
(2, 2, 'buy', 15.000000, 170.5000, 2557.5000, '2026-04-01 10:20:00', 'Tesla growth trade'),
(3, 5, 'buy', 200.000000, 0.7000, 140.0000, '2026-04-02 11:00:00', 'Income stock allocation'),
(4, 6, 'buy', 25.000000, 96.0000, 2400.0000, '2026-04-02 13:10:00', 'European exposure'),
(5, 8, 'buy', 1000.000000, 1.0800, 1080.0000, '2026-04-03 09:45:00', 'FX position'),
(6, 7, 'buy', 12.000000, 148.5000, 1782.0000, '2026-04-03 14:30:00', 'Bond allocation'),
(7, 3, 'buy', 0.250000, 63500.0000, 15875.0000, '2026-04-04 15:10:00', 'Bitcoin diversification'),
(8, 4, 'buy', 2.500000, 3100.0000, 7750.0000, '2026-04-04 16:25:00', 'Ethereum momentum trade');

-- ------------------------------------------------------------
-- Insert data into market_prices
-- ------------------------------------------------------------
INSERT INTO market_prices (asset_id, price_date, open_price, close_price, high_price, low_price, volume)
VALUES
(1, '2026-04-10', 188.0000, 189.4500, 190.1000, 187.5000, 52000000),
(2, '2026-04-10', 170.0000, 172.8800, 174.2000, 169.4000, 41000000),
(3, '2026-04-10', 63800.0000, 64250.0000, 64800.0000, 63400.0000, 1850000),
(4, '2026-04-10', 3090.0000, 3150.5000, 3188.0000, 3075.0000, 920000),
(5, '2026-04-10', 0.6900, 0.7100, 0.7200, 0.6850, 68000000),
(6, '2026-04-10', 97.1000, 98.3500, 99.0000, 96.8000, 2100000),
(7, '2026-04-10', 148.0000, 149.2200, 150.0000, 147.8000, 350000),
(8, '2026-04-10', 1.0790, 1.0845, 1.0860, 1.0780, 73000000);



-- ============================================================
-- SECTION 4: RETRIEVE DATA — SELECT QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Query 1: Full investor directory, sorted alphabetically
-- This query retrieves a complete list of all registered investors
-- including their contact details, country, risk profile, and join date.
-- It uses CONCAT to display the investor’s full name in a single column
-- and sorts the results alphabetically by last name and first name.
-- ------------------------------------------------------------
SELECT
    investor_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    country,
    risk_profile,
    joined_date
FROM investors
ORDER BY last_name, first_name;


-- ------------------------------------------------------------
-- Query 2: All assets with their currency and current price
-- This query displays all assets together with their category,
-- trading currency, current market price, and exchange platform.
-- It joins the assets and currencies tables to show the currency
-- symbol and sorts the results by asset type and highest price first.
-- ------------------------------------------------------------
SELECT
    a.ticker,
    a.asset_name,
    a.asset_type,
    c.symbol AS currency_symbol,
    a.currency_code,
    a.current_price,
    a.exchange
FROM assets AS a
JOIN currencies AS c
    ON a.currency_code = c.currency_code
ORDER BY a.asset_type, a.current_price DESC;


-- ------------------------------------------------------------
-- Query 3: Complete transaction history with readable names
-- This query generates a full transaction history by combining
-- data from investors, portfolios, assets, and currencies.
-- It uses multi-table JOIN operations, formatted prices, and a
-- readable date format to present transaction records clearly.
-- ------------------------------------------------------------
SELECT
    t.transaction_id,
    CONCAT(i.first_name, ' ', i.last_name) AS investor_name,
    p.portfolio_name,
    a.ticker,
    a.asset_name,
    t.transaction_type,
    t.quantity,
    CONCAT(c.symbol, FORMAT(t.price_at_txn, 2)) AS price,
    CONCAT(c.symbol, FORMAT(t.total_value, 2)) AS total,
    DATE_FORMAT(t.transaction_date, '%d %b %Y') AS transaction_date
FROM transactions AS t
JOIN portfolios AS p
    ON t.portfolio_id = p.portfolio_id
JOIN investors AS i
    ON p.investor_id = i.investor_id
JOIN assets AS a
    ON t.asset_id = a.asset_id
JOIN currencies AS c
    ON a.currency_code = c.currency_code
ORDER BY t.transaction_date DESC;


-- ------------------------------------------------------------
-- Query 4: Portfolio summary per investor
-- This query provides a summary of each investor’s portfolio
-- by showing transaction count, total invested amount, total sold
-- amount, and the date range of trading activity.
-- It uses aggregate functions such as COUNT, SUM, MIN, and MAX,
-- together with GROUP BY, to analyse portfolio-level performance.
-- ------------------------------------------------------------
SELECT
    CONCAT(i.first_name, ' ', i.last_name) AS investor_name,
    i.risk_profile,
    p.portfolio_name,
    p.base_currency_code,
    COUNT(t.transaction_id) AS total_trades,
    SUM(CASE WHEN t.transaction_type = 'buy' THEN t.total_value ELSE 0 END) AS total_invested,
    SUM(CASE WHEN t.transaction_type = 'sell' THEN t.total_value ELSE 0 END) AS total_sold,
    MIN(t.transaction_date) AS first_trade,
    MAX(t.transaction_date) AS last_trade
FROM investors AS i
JOIN portfolios AS p
    ON i.investor_id = p.investor_id
LEFT JOIN transactions AS t
    ON p.portfolio_id = t.portfolio_id
GROUP BY i.investor_id, p.portfolio_id
ORDER BY total_invested DESC;


-- ------------------------------------------------------------
-- Query 5: Most traded assets ranked by transaction value
-- This query identifies the most actively traded assets by
-- calculating the number of trades, total units traded, and
-- total transaction value for each asset.
-- It uses aggregate functions such as COUNT, SUM, and AVG
-- to evaluate trading activity and rank assets by value traded.
-- ------------------------------------------------------------
SELECT
    a.ticker,
    a.asset_name,
    a.asset_type,
    COUNT(t.transaction_id) AS number_of_trades,
    SUM(t.quantity) AS total_units_traded,
    SUM(t.total_value) AS total_value_traded,
    AVG(t.price_at_txn) AS average_trade_price
FROM assets AS a
JOIN transactions AS t
    ON a.asset_id = t.asset_id
GROUP BY a.asset_id
ORDER BY total_value_traded DESC;


-- ------------------------------------------------------------
-- Query 6: Price performance summary per asset
-- This query summarises the market price performance of each asset
-- by calculating average closing price, highest price, lowest price,
-- price range, and estimated volatility percentage.
-- It uses aggregate functions and calculated fields based on data
-- from the market_prices table to analyse price fluctuations.
-- ------------------------------------------------------------
SELECT
    a.ticker,
    a.asset_name,
    a.asset_type,
    ROUND(AVG(mp.close_price), 4) AS avg_close_price,
    MAX(mp.high_price) AS highest_price,
    MIN(mp.low_price) AS lowest_price,
    ROUND(MAX(mp.high_price) - MIN(mp.low_price), 4) AS price_range,
    ROUND((MAX(mp.high_price) - MIN(mp.low_price)) / AVG(mp.close_price) * 100, 2) AS volatility_pct
FROM assets AS a
JOIN market_prices AS mp
    ON a.asset_id = mp.asset_id
GROUP BY a.asset_id
ORDER BY volatility_pct DESC;


-- ------------------------------------------------------------
-- Query 7: Investors who have bought crypto assets
-- This query lists investors who have purchased crypto assets,
-- together with their country, risk profile, and the crypto asset bought.
-- It uses DISTINCT to avoid duplicate investor-asset combinations
-- and applies filtering conditions to return only buy transactions
-- involving assets classified as crypto.
-- ------------------------------------------------------------
SELECT DISTINCT
    CONCAT(i.first_name, ' ', i.last_name) AS investor_name,
    i.country,
    i.risk_profile,
    a.ticker AS crypto_asset,
    a.asset_name
FROM investors AS i
JOIN portfolios AS p
    ON i.investor_id = p.investor_id
JOIN transactions AS t
    ON p.portfolio_id = t.portfolio_id
JOIN assets AS a
    ON t.asset_id = a.asset_id
WHERE a.asset_type = 'crypto'
  AND t.transaction_type = 'buy'
ORDER BY investor_name, a.ticker;


-- ------------------------------------------------------------
-- Query 8: Estimated unrealised P&L based on average buy price
-- This query calculates the estimated unrealised profit or loss
-- for each investor’s holdings by comparing the average purchase
-- price of assets with their current market price.
-- It uses aggregation (SUM, AVG) and a calculated percentage
-- to measure potential performance.
-- This is a simplified estimate based only on buy transactions and does not subtract sold quantities.
-- ------------------------------------------------------------
SELECT
    CONCAT(i.first_name, ' ', i.last_name) AS investor_name,
    p.portfolio_name,
    a.ticker,
    a.asset_name,
    SUM(t.quantity) AS units_bought,
    ROUND(AVG(t.price_at_txn), 4) AS avg_buy_price,
    a.current_price,
    ROUND(
        (a.current_price - AVG(t.price_at_txn))
        / AVG(t.price_at_txn) * 100,
        2
    ) AS estimated_unrealised_pnl_pct
FROM transactions AS t
JOIN portfolios AS p
    ON t.portfolio_id = p.portfolio_id
JOIN investors AS i
    ON p.investor_id = i.investor_id
JOIN assets AS a
    ON t.asset_id = a.asset_id
WHERE t.transaction_type = 'buy'
GROUP BY i.investor_id, p.portfolio_id, a.asset_id
ORDER BY estimated_unrealised_pnl_pct DESC;


-- ============================================================
-- SECTION 5: SUBQUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Query 9: Assets priced above the average current asset price
-- This subquery identifies all assets whose current market price
-- is higher than the average current price across all assets.
-- It uses a subquery in the WHERE clause to compare each asset
-- against the overall average and sorts the results by price
-- from highest to lowest.
-- ------------------------------------------------------------
SELECT
    ticker,
    asset_name,
    asset_type,
    current_price
FROM assets
WHERE current_price > (
    SELECT AVG(current_price)
    FROM assets
)
ORDER BY current_price DESC;


-- ------------------------------------------------------------
-- Query 10: Assets with the highest current price
-- This subquery finds the asset or assets with the highest
-- current market price in the database.
-- It uses a subquery to retrieve the maximum current price
-- and returns all matching assets in case of a tie.
-- ------------------------------------------------------------
SELECT
    ticker,
    asset_name,
    asset_type,
    current_price
FROM assets
WHERE current_price = (
    SELECT MAX(current_price)
    FROM assets
);

-- ============================================================
-- SECTION 6: UPDATE DATA
-- ============================================================

-- ------------------------------------------------------------
-- Update 1: Refresh the current market price of Apple Inc.
-- This query simulates a routine market data update after the
-- latest trading session. The assets table stores the current
-- market price of each financial instrument, so this update
-- reflects a new closing price for Apple shares.
-- ------------------------------------------------------------
UPDATE assets
SET current_price = 191.2500
WHERE ticker = 'AAPL';

-- Verify the updated asset price
SELECT
    ticker,
    asset_name,
    current_price
FROM assets
WHERE ticker = 'AAPL';


-- ------------------------------------------------------------
-- Update 2: Change Maya Patel's risk profile after review
-- This query updates an investor's risk classification following
-- a portfolio suitability review. In a real investment platform,
-- this could happen after the investor completes a new risk
-- assessment questionnaire or changes investment objectives.
-- ------------------------------------------------------------
UPDATE investors
SET risk_profile = 'moderate'
WHERE email = 'maya.patel@email.com';

-- Verify the updated investor profile
SELECT
    investor_id,
    CONCAT(first_name, ' ', last_name) AS full_name,
    risk_profile
FROM investors
WHERE email = 'maya.patel@email.com';



-- ============================================================
-- SECTION 7: DELETE DATA
-- ============================================================

-- ------------------------------------------------------------
-- Delete: Remove a transaction entered in error
-- This section demonstrates how an incorrect transaction can be
-- safely removed from the database. A temporary duplicate entry
-- is inserted, verified, deleted, and then the table is checked
-- again to confirm successful removal.
-- ------------------------------------------------------------

-- Insert a temporary duplicate transaction (entered in error)
INSERT INTO transactions 
    (portfolio_id, asset_id, transaction_type, quantity, price_at_txn, total_value, transaction_date, notes)
VALUES
    (1, 1, 'buy', 5.000000, 189.4500, 947.2500, '2026-04-11 08:00:00', 'DUPLICATE ENTRY - entered in error');


-- Verify the record before deletion
SELECT
    transaction_id,
    portfolio_id,
    asset_id,
    transaction_type,
    quantity,
    total_value,
    transaction_date,
    notes
FROM transactions
WHERE notes = 'DUPLICATE ENTRY - entered in error';


-- Delete the incorrect duplicate transaction
DELETE FROM transactions 
WHERE notes = 'DUPLICATE ENTRY - entered in error';


-- Confirm that the record has been removed
SELECT
    transaction_id,
    portfolio_id,
    asset_id,
    transaction_type,
    quantity,
    total_value,
    transaction_date,
    notes
FROM transactions
ORDER BY transaction_date DESC;



-- ============================================================
-- SECTION 8: STORED PROCEDURE
-- ============================================================

-- ------------------------------------------------------------
-- Procedure: get_portfolio_risk_report
-- This stored procedure accepts an investor ID and generates a
-- portfolio allocation report grouped by asset type.
-- It calculates the total amount invested in each category,
-- the number of different assets held, and the percentage
-- allocation of the portfolio. This helps assess whether an
-- investor is concentrated in higher-risk or lower-risk assets.
-- ------------------------------------------------------------

DELIMITER $$

CREATE PROCEDURE get_portfolio_risk_report(IN p_investor_id INT)
BEGIN
    DECLARE v_total_invested DECIMAL(15, 4);

    -- Calculate the investor's total buy-side investment value
    SELECT SUM(t.total_value)
    INTO v_total_invested
    FROM transactions AS t
    JOIN portfolios AS p
        ON t.portfolio_id = p.portfolio_id
    WHERE p.investor_id = p_investor_id
      AND t.transaction_type = 'buy';

    -- Return allocation summary by asset type
    SELECT
        CONCAT(i.first_name, ' ', i.last_name) AS investor_name,
        i.risk_profile,
        a.asset_type,
        COUNT(DISTINCT a.asset_id) AS number_of_assets,
        ROUND(SUM(t.total_value), 2) AS amount_invested,
        ROUND(SUM(t.total_value) / v_total_invested * 100, 2) AS allocation_pct
    FROM investors AS i
    JOIN portfolios AS p
        ON i.investor_id = p.investor_id
    JOIN transactions AS t
        ON p.portfolio_id = t.portfolio_id
    JOIN assets AS a
        ON t.asset_id = a.asset_id
    WHERE i.investor_id = p_investor_id
      AND t.transaction_type = 'buy'
    GROUP BY i.investor_id, i.risk_profile, a.asset_type
    ORDER BY amount_invested DESC;
END$$

DELIMITER ;

-- Run the procedure for sample investors
CALL get_portfolio_risk_report(2);
CALL get_portfolio_risk_report(5);
CALL get_portfolio_risk_report(8);

