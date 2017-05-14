
function validateInet(inputField, fieldDesc)
{
    var value = $F(inputField);
    if (!value)
    {
        return; // Its not populated...
    }
    var quad1; var quad2; var quad3; var quad4;
    var isValid = 1;
    if (value.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/))
    {
        quad1 = parseInt($1);
        quad2 = parseInt($2);
        quad3 = parseInt($3);
        quad4 = parseInt($4);
        if (quad1 >= 255 || quad2 >= 255 || quad3 >= 255 || quad4 >= 255)
        {
            isValid = 0;
        }
    }
    else
    {
        isValid = 0;
    }
    if (isValid == 0)
    {
        alert(fieldDesc + ': \'' + value + '\' is not a valid IP address');
        inputField.value = '';
    }
    return;
}

function validateBigInt(inputField, fieldDesc)
{
    var value = $F(inputField);
    var num;
    try {
        if (isNaN(value))
        {
            throw('NaN');
        }
        num = parseInt(value);
    }
    catch(e)
    {
        alert(fieldDesc + ': \'' + value + '\' is not a valid number');
        inputField.value = '';
    }
    if (num < -9223372036854775808 || num > 9223372036854775807)
    {
        alert(fieldDesc+ ': \'' + value + '\' is not between the ranges -9223372036854775808 to 9223372036854775807');
        inputField.value = '';
    }
    return;
}

function validateInteger(inputField, fieldDesc)
{
    var value = $F(inputField);
    var num;
    try {
        if (isNaN(value))
        {
            throw('NaN');
        }
        num = parseInt(value);
    }
    catch(e)
    {
        alert(fieldDesc + ': \'' + value + '\' is not a valid number');
        inputField.value = '';
    }
    if (num < -2147483648 || num > 2147483647)
    {
        alert(fieldDesc + ': \'' + value + '\' is not between the ranges -2147483648 to 2147483647');
        inputField.value = '';
    }
    return;
}

function validateSmallInt(inputField, fieldDesc)
{
    var value = $F(inputField);
    var num;
    try {
        if (isNaN(value))
        {
            throw('NaN');
        }
        num = parseInt(value);
    }
    catch(e)
    {
        alert(fieldDesc + ': \'' + value + '\' is not a valid number');
        inputField.value = '';
    }
    if (num < -32768 || num > 32767)
    {
        alert(fieldDesc + ': \'' + value + '\' is not between the ranges -32768 to 32767');
        inputField.value = '';
    }
    return;
}

function validateDate(inputField, fieldDesc)
{
    var value = $F(inputField);
    if (!value)
    {
        return;
    }
    var dd; var mm; var yyyy;
    if (value.match(/^(\d\d\d\d)(\/|\-)(\d+)(\/|\-)(\d+)$/))
    {
        yyyy = parseInt($1);
        mm = parseInt($3);
        dd = parseInt($5);
    }
    else
    {
        alert(fieldDesc + ': \'' + value + '\' is not a valid date (YYYY-MM-DD)');
        inputField.value = '';
        return;
    }
    try {
        date = new Date(yyyy, mm - 1, dd);
        if (mm > 12 || dd > 31)
        {
            throw('OutOfRange');
        }
    }
    catch(e)
    {
        alert(fieldDesc + ': \'' + value + '\' is not a valid date (YYYY-MM-DD)');
        inputField.value = '';
        return;
    }
    return;
}

