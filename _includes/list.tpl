{% include header.tpl %}

{% for post in list limit:limitation %}
{% capture this_year %}{{ post.date | date: "%Y" }}{% endcapture %}
{% capture next_year %}{{ post.previous.date | date: "%Y" }}{% endcapture %}

{% if this_year != last_year %}
{% unless forloop.first %}
	</ul>
</section>
{% endunless %}
<section>
	<h2>{{ this_year }}</h2>
	<ul>
{% endif %}
	<li><time>{{ post.date | date: "%Y-%m-%d" }}</time><a href="{{ post.url }}">{{ post.title }}</a></li>
{% if forloop.last %}
	</ul>
</section>
{% endif %}
{% capture last_year %}{{ this_year }}{% endcapture %}

{% endfor %}

{% if list == null %}
<article class="empty">
	<p>该分类下还没有文章</p>
</article>
{% endif %}
