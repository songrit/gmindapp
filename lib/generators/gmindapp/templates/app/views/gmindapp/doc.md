CSS: style.css
Use numbered headers: true
HTML use syntax: true
LaTeX use listings: true
LaTeX CJK: false
LaTeX preamble: preamble.tex

<style>code { font-size: 0.8em;}</style>


{:ruby:     lang=ruby code_background_color='#efffef'}
{:shell:    lang=sh code_background_color='#efefff'}
{:markdown: code_background_color='#ffefef'}
{:html:     lang=xml}

สารบัญ
=====

* This list will contain the toc (it doesn't matter what you write here)
{:toc}

* * *

<%= @name %>
============
<%= @intro %>

* * *

คู่มือการใช้งาน
===========
* ระบบงานย่อย 1
  * งาน 1 ; หน้าจอ, หน้าจอ, หน้าจอ
  * งาน 2
* ระบบงานย่อย 2
* ระบบงานย่อย 3

* * *
คู่มือผู้ดูแลระบบ
===========
โครงสร้างข้อมูล
------------

<%- models= @app.elements["//node[@TEXT='models']"] %>

<%= render :partial=>'gmindapp/model.md', :collection=> models.map {|m| m.attributes["TEXT"]} %>

source code
-----------

ภาคผนวก
=======

markdown
--------
คู่มือนี้จัดทำขึ้นโดยอัตโนมัติจาก mind map และรหัสโปรแกรม ผู้พัฒนาสามารถเขียนวิธีการใช้งานได้อย่างอิสระ
โดยใช้คำสั่ง markdown ในการเขียนคู่มือประกอบเข้ากับส่วนต่างๆของระบบงาน รายละเอียดคำสั่งต่างๆของ markdown 
สามารถดูได้จาก [http://maruku.rubyforge.org/markdown_syntax.html](http://maruku.rubyforge.org/markdown_syntax.html)
