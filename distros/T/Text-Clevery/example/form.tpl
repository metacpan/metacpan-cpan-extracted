<!doctype html>
<html>
<head><title>{$title}</title></head>
<body>
<h1>{$title}</h1>
<form>
{html_options name="fruit"
    values=$ids output=$names selected=`$smarty.get.fruit` }<br />
{html_select_date}<br />
{html_select_time}<br />
<input type="submit" />
</form>
</body>
</html>
