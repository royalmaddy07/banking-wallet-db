use banking_wallet_db;

delimiter $$
create procedure transaction_logic(in fromAccID bigint, in toAccID bigint, in amount decimal(20,5), in transactionType varchar(10))
begin
	-- local variables declaration
    declare senderBalance decimal(20,5);
	declare senderStatus varchar(10);
    declare recieverStatus varchar(10);
    declare txID bigint;
    
	declare exit handler for sqlexception
    begin
		rollback; -- on any sql error will result in a rollback
    end;
    
    -- doing some basic validation checks before starting the transaction 
    if (amount<=0) then
		signal sqlstate '45000'
		set message_text = 'Transfer amount must be positive';
	end if;
    
    if (toAccID = fromAccID) then
		signal sqlstate '45000'
        set message_text = 'sender and reciever cannot be same';
	end if;
    
    start transaction;
	-- 1.) locking the senderand reciever rows for the transaction 
    select balance, status into senderBalance, senderStatus from accounts where accountID = fromAccID for update;
    select status into recieverStatus from accounts where accountID = toAccID for update;
		
	-- 2.) doing important validation checksum table
    if senderBalance = null then
		signal sqlstate '45000'
        set message_text = 'sender account doesnot exists';
	end if;
    
    if senderStatus <> 'active' then
		signal sqlstate '45000'
        set message_text = 'sender account not active';
	end if;
    
    if (senderBalance < amount) then
		signal sqlstate '45000'
        set message_text = 'insufficient balance';
	end if;
    
    if (recieverStatus = null) then
		signal sqlstate '45000'
        set message_text = 'reciever account doesnot exists';
	end if;
    
    if (reciverStatus <> 'active') then
		signal sqlstate '45000'
        set message_text = 'reciever account is not active';
	end if;

	-- 3.) create a transaction record(intent) -> insert into transactions table and set status = 'pending'

	-- 4.) apply balance changes ->

	-- a.) debit sender -> reduce balance

	-- b.) credit reciever -> increase balance

	-- 5.) write ledge entries -> 2 entries
	-- 1 entry for debit and 1 entry for credit

	-- 6.) finalize transaction 
	-- if everything executed successfully -> commit and set status='success'
	-- if any step failed -> rollback and set status='failed'
end $$
delimiter ;