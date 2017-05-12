List:
{foreach from=$data item=it name="i"}
    {if $smarty.foreach.i.first}
    -------------------------------
    {/if}
    { $smarty.foreach.i.iteration }. { $it.title }
    -------------------------------
{/foreach}
