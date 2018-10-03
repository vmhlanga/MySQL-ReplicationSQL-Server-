use YourDBName
go 

declare @openquery	nvarchar (max), @schema varchar(100), @sql nvarchar (max), @linkedserver nvarchar (max), @id varchar(30), @tblcnt int , @TableName varchar(100),@clmnName varchar(100), @sql_tble varchar(255),@tbldID bigint

begin try drop table #TablesToReplicate end try begin catch end catch

create table #TablesToReplicate(id bigint identity(1,1), TableName varchar(100), Column_Name varchar(200),TableName_Query varchar(255) )
declare  @maxId_tbl table (Id bigint) 
 
set @LinkedServer='[lnkdserver]'--your linked server to Mysql 
set @schema = 'Mysql Schema Name'
set @openquery='SELECT * FROM openquery('+@LinkedServer+','''

set @sql = 'select t.table_name, k.column_name,CONCAT('''''''',''''select * from '''',t.table_schema,''''.'''',t.table_name,'''' where '''', k.column_name, '''' > '''') as TableName_Query FROM information_schema.table_constraints t JOIN information_schema.key_column_usage k USING(constraint_name,table_schema,table_name)
					WHERE t.constraint_type=''''PRIMARY key'''' AND t.table_schema='''''+@schema+''''''')'

insert into #TablesToReplicate(TableName, Column_Name, TableName_Query)
exec(@openquery+@sql)

set @tblcnt = @@rowcount

	while (@tblcnt > 0)
		begin
			
			select top 1 @tbldID=ttr.id, @TableName = ttr.TableName, @sql_tble= ttr.TableName_Query, @clmnName = ttr.Column_Name from #TablesToReplicate ttr

			if exists( select 1 from sys.tables  o where o.name = @TableName)
				begin 
					
					insert into @maxId_tbl(Id)
					exec ('select isnull(max('+@clmnName+'),0) from dbo.'+@TableName);

					set @id = (select mit.Id from @maxId_tbl mit)

					set @sql = @sql_tble +''+@id+''''+')'
					set @TableName = 'dbo.'+@TableName
					
					print @TableName				
					exec('insert into '+@TableName+' '+@openquery+@sql)

				end
				
			set @tblcnt = @tblcnt - 1
			delete from @maxId_tbl
			delete from #TablesToReplicate where id = @tbldID   
		end
