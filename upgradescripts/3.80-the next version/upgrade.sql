﻿--upgrade scripts from nopCommerce 3.80 to next version

--new locale resources
declare @resources xml
--a resource will be deleted if its value is empty
set @resources='
<Language>
  <LocaleResource Name="Account.CustomerProductReviews.NoRecords">
    <Value>You haven''t written any reviews yet</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.CustomerUser.EnteringEmailTwice.Hint">
    <Value>Force entering email twice during registration.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.Vendor.MaximumProductNumber.Hint">
    <Value>Sets a maximum number of products per vendor.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Shipping.Methods.Description">
    <Value>Shipping methods used by offline shipping rate computation methods (e.g. "Fixed Rate Shipping" or "Shipping by weight").</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.Fields.Price.Hint">
    <Value>The price of the product. You can manage currency by selecting Configuration > Currencies.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Customers.Customers.Fields.CustomerRoles.Hint">
    <Value>Choose customer roles of this user.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.Catalog.ExportImportProductAttributes.Hint">
    <Value>Check if products should be exported/imported with product attributes.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.Shipping.ShipToSameAddress.Hint">
    <Value>Check to display "ship to the same address" option during checkout ("billing address" step). In this case "shipping address" with appropriate options (e.g. pick up in store) will be skipped. Also note that all billing countries should support shipping ("Allow shipping" checkbox ticked).</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.System.ScheduleTasks.24days">
    <Value>Task period should not exceed 24 days.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Payment.MethodRestrictions">
    <Value>Payment restrictions</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.Fields.Vendor.Hint">
    <Value>Choose a vendor associated with this product. This can be useful when running a multi-vendor store to keep track of goods associated with vendor.</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Countries.ImportTip">
    <Value>You can download a CSV file with a list of states for other countries on the following page:</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.Fields.ProductTags.Placeholder">
    <Value>Enter tags ...</Value>
  </LocaleResource>
  <LocaleResource Name=" Admin.Catalog.Categories.Fields.Parent.None">
    <Value>[None]</Value>
  </LocaleResource>  
  <LocaleResource Name="Admin.Configuration.Settings.Shipping.HideShippingTotal">
    <Value>Hide shipping total if shipping not required</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Configuration.Settings.Shipping.HideShippingTotal.Hint">
    <Value>Check if you want Hide ''Shipping total'' label if shipping not required.</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ApiAccountName">
    <Value></Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ApiAccountName.Hint">
    <Value></Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ApiAccountPassword">
    <Value></Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ApiAccountPassword.Hint">
    <Value></Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.Signature">
    <Value></Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.Signature.Hint">
    <Value></Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ClientId">
    <Value>Client ID</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ClientId.Hint">
    <Value>Specify client ID.</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ClientSecret">
    <Value>Client secret</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.ClientSecret.Hint">
    <Value>Specify secret key.</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.WebhookId">
    <Value>Webhook ID</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.Fields.WebhookId.Hint">
    <Value>Specify webhook ID.</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.WebhookCreate">
    <Value>Get webhook ID</Value>
  </LocaleResource>
  <LocaleResource Name="Plugins.Payments.PayPalDirect.WebhookError">
    <Value>Webhook was not created (see details in the log)</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.ProductAttributes.Attributes.Values.Fields.CustomerEntersQty">
    <Value>Customer enters quantity</Value>
  </LocaleResource>
  <LocaleResource Name="Admin.Catalog.Products.ProductAttributes.Attributes.Values.Fields.CustomerEntersQty.Hint">
    <Value>Allow customers enter the quantity of associated product.</Value>
  </LocaleResource>
  <LocaleResource Name="ProductAttributes.Quantity">
    <Value> - quantity {0}</Value>
  </LocaleResource>
  <LocaleResource Name="Products.ProductAttributes.PriceAdjustment">
    <Value>{0} [{1}{2}]</Value>
  </LocaleResource>
  <LocaleResource Name="Products.ProductAttributes.PriceAdjustment.PerItem">
    <Value> per item</Value>
  </LocaleResource>
  <LocaleResource Name="Products.ProductAttributes.PriceAdjustment.Quantity">
    <Value>Enter quantity</Value>
  </LocaleResource>  
</Language>
'

CREATE TABLE #LocaleStringResourceTmp
	(
		[ResourceName] [nvarchar](200) NOT NULL,
		[ResourceValue] [nvarchar](max) NOT NULL
	)

INSERT INTO #LocaleStringResourceTmp (ResourceName, ResourceValue)
SELECT	nref.value('@Name', 'nvarchar(200)'), nref.value('Value[1]', 'nvarchar(MAX)')
FROM	@resources.nodes('//Language/LocaleResource') AS R(nref)

--do it for each existing language
DECLARE @ExistingLanguageID int
DECLARE cur_existinglanguage CURSOR FOR
SELECT [ID]
FROM [Language]
OPEN cur_existinglanguage
FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
WHILE @@FETCH_STATUS = 0
BEGIN
	DECLARE @ResourceName nvarchar(200)
	DECLARE @ResourceValue nvarchar(MAX)
	DECLARE cur_localeresource CURSOR FOR
	SELECT ResourceName, ResourceValue
	FROM #LocaleStringResourceTmp
	OPEN cur_localeresource
	FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (EXISTS (SELECT 1 FROM [LocaleStringResource] WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName))
		BEGIN
			UPDATE [LocaleStringResource]
			SET [ResourceValue]=@ResourceValue
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		ELSE 
		BEGIN
			INSERT INTO [LocaleStringResource]
			(
				[LanguageId],
				[ResourceName],
				[ResourceValue]
			)
			VALUES
			(
				@ExistingLanguageID,
				@ResourceName,
				@ResourceValue
			)
		END
		
		IF (@ResourceValue is null or @ResourceValue = '')
		BEGIN
			DELETE [LocaleStringResource]
			WHERE LanguageID=@ExistingLanguageID AND ResourceName=@ResourceName
		END
		
		FETCH NEXT FROM cur_localeresource INTO @ResourceName, @ResourceValue
	END
	CLOSE cur_localeresource
	DEALLOCATE cur_localeresource


	--fetch next language identifier
	FETCH NEXT FROM cur_existinglanguage INTO @ExistingLanguageID
END
CLOSE cur_existinglanguage
DEALLOCATE cur_existinglanguage

DROP TABLE #LocaleStringResourceTmp
GO

--new setting
IF NOT EXISTS (SELECT 1 FROM [Setting] WHERE [name] = N'shippingsettings.hideshippingtotal')
BEGIN
	INSERT [Setting] ([Name], [Value], [StoreId])
	VALUES (N'shippingsettings.hideshippingtotal', N'False', 0)
END
GO

--new column
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=object_id('[ProductAttributeValue]') and NAME='CustomerEntersQty')
BEGIN
	ALTER TABLE [ProductAttributeValue]
	ADD [CustomerEntersQty] bit NULL
END
GO

UPDATE [ProductAttributeValue]
SET [CustomerEntersQty] = 0
WHERE [CustomerEntersQty] IS NULL
GO

ALTER TABLE [ProductAttributeValue] ALTER COLUMN [CustomerEntersQty] bit NOT NULL
GO

--new or update setting
IF NOT EXISTS (SELECT 1 FROM [Setting] WHERE [name] = N'shoppingcartsettings.renderassociatedattributevaluequantity')
BEGIN
	INSERT [Setting] ([Name], [Value], [StoreId]) 
	VALUES (N'shoppingcartsettings.renderassociatedattributevaluequantity', N'True', 0);
END
ELSE
BEGIN
	UPDATE [Setting] 
	SET [Value] = N'True' 
	WHERE [Name] = N'shoppingcartsettings.renderassociatedattributevaluequantity'
END
GO

