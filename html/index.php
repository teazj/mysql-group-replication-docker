<?php
header("content-type:text/html;charset=utf-8");
$conn=@mysql_connect("127.0.0.1","root","");

if(!$conn){
        echo "<h2>错误编码:".mysql_errno()."</h2>";
        echo "<h2>错误编码:".mysql_error()."</h2>";
}else{

        mysql_select_db("test");
        mysql_query("set names utf8");
        $length=10;
        $pagenum=$_GET['page']?$_GET['page']:1;
        $totsql="select count(*) from t3";
        $totarr=mysql_fetch_row($totrst=mysql_query($totsql));
        $pagetot=ceil($totarr[0]/$length);
        if($pagenum>=$pagetot){
                $pagenum=$pagetot;
        }
        $offset=($pagenum-1)*$length;
        $sql="select * from t3 order by id limit {$offset},{$length}";
        $rst=mysql_query($sql);
        echo "<center>";
        echo "<h2>用户信息表</h2>";
        echo "<table width='700px' border='1px'>";
        while ($row=mysql_fetch_assoc($rst)) {
                echo "<tr>";
                echo "<td>{$row['id']}</td>";
                echo "<td>{$row['name']}</td>";
                echo "<td>{$row['sex']}</td>";
                echo "</tr>";
        }
        echo "</table>";

        $prevpage=$pagenum-1;
        $nextpage=$pagenum+1;
        echo "<h2><a href='index.php?page={$prevpage}'>上一页</a> | <a href='index.php?page={$nextpage}'>下一页</a></h2>";
        echo "</center>";
        mysql_free_result($totrst);
        mysql_free_result($rst);
        mysql_close($conn);
}
