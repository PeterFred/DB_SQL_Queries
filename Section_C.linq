<Query Kind="Statements">
  <Connection>
    <ID>277ed0c6-08a7-4630-a561-a71c7cc493e4</ID>
    <Persist>true</Persist>
    <Driver Assembly="IQDriver" PublicKeyToken="5b59726538a49684">IQDriver.IQDriver</Driver>
    <Provider>Devart.Data.Oracle</Provider>
    <CustomCxString>AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAQWD+UV/J3EGRSUej0dy9wQAAAAACAAAAAAADZgAAwAAAABAAAABZL4BsANeCu+Y3WBhtYtGpAAAAAASAAACgAAAAEAAAAHlrgUwQVqOvd2TCqT9M0kZgAAAAqYahb3us51dk9JHHG5S0YSZrjRpbtBzl3NiLffazUaHBg8rAH0jVHlGD6WBbrROr/eIfWrdEkqh8mACAGxYdT0HFmEO+UNDHGcbCkTVoTaKxe6AZzbX5zkJmpHwEBr1LFAAAAOeXZCkhsavIzPw0COfUqJpBHIIM</CustomCxString>
    <Server>inms-oracle.massey.ac.nz</Server>
    <UserName>Group02</UserName>
    <Password>AQAAANCMnd8BFdERjHoAwE/Cl+sBAAAAQWD+UV/J3EGRSUej0dy9wQAAAAACAAAAAAADZgAAwAAAABAAAABy2n99l1aLJTuju+iWNTzIAAAAAASAAACgAAAAEAAAAHG6sy7vqaIm1Kw54V7dpyYIAAAAF5M/q+w9MwAUAAAANdsOMNaDiBbQYbrhmk80XPUoScQ=</Password>
    <DisplayName>Assignment2</DisplayName>
    <EncryptCustomCxString>true</EncryptCustomCxString>
    <DriverData>
      <StripUnderscores>true</StripUnderscores>
      <QuietenAllCaps>true</QuietenAllCaps>
      <ConnectAs>Default</ConnectAs>
      <UseOciMode>false</UseOciMode>
      <SID>orcl</SID>
      <Port>1521</Port>
    </DriverData>
  </Connection>
</Query>

//q. List all books with the retail $22 or over. (1 mark)
var over22 = 
	from b in Books
	where b.BookRetail >= 22
	select b;

over22.Dump();

//r. List all books that have the word “HOW” in the book title. (1 mark)
var containsHow =
	from b in Books
	where b.BookTitle.Contains("HOW")
	select b;

containsHow.Dump();
	
//s. List all book categories, book titles and publisher names. (1 mark)	
var BookDetails = 
	from b in Books join p in Publishers
	on b.BookPubid equals p.PubID
	select new{
	BookTitle = b.BookTitle,
	Category = b.BookCategory,
	Publisher = p.PubName};
BookDetails.Dump();

//t. Display total number of books by each publisher in the order of publisher ID. (1.5 marks)
var BookTotalByPublisher = 
	from b in Books join p in Publishers
	on b.BookPubid equals p.PubID 
	group b.BookPubid  by new{
		ID = b.BookPubid,
		Name = p.PubName	
	}
	into T
	select new{
		ID = T.Key.ID,
		PublisherName = T.Key.Name,
		Count = T.Count()		
	};
BookTotalByPublisher.Dump();

//u. Display the count of books in each category in the increasing order of category. (1.5 marks)
//Im assuming the above means in alphabetical order of the category.
var BooksInCategory = 
	from b in Books
	group b.BookCategory by 
	new{
		Category = b.BookCategory
	}into T
	orderby T.Key.Category ascending
	select new{
		Category = T.Key.Category,
		Count = T.Count()
	};

BooksInCategory.Dump();
	


