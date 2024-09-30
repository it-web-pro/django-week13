# Django REST Framework - Part 1

## Installation

ทำการติดตั้งด้วยคำสั่ง pip

```sh
pip install djangorestframework
```

เพิ่ม "rest_framework" ใน INSTALLED_APP ใน `settings.py`

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
]
```

## Let's do a quick tutorial

เรามาเริ่มด้วยการสร้าง project กันก่อน

```sh
# Create the project directory
mkdir tutorial
cd tutorial

# Create a virtual environment to isolate our package dependencies locally
py -m venv myvenv
myvenv\Scripts\activate.bat  # On Mac use `source myvenv/bin/activate`

# Install Django and Django REST framework into the virtual environment
pip install django psycopg2 
pip install djangorestframework pygments

# Set up a new project with a single application
django-admin startproject week13_tutorial
cd week13_tutorial
python manage.py startapp snippets
```

ทำการเพิ่ม "snippets" และ "rest_framework" ใน INSTALLED_APPS และ แก้ไข connection ของ database ให้ถูกต้อง (สร้าง DB ชื่อ snippets ใน Postgres ด้วย)

```python
INSTALLED_APPS = [
    ...
    'rest_framework',
    'snippets',
]
```

### Creating a model to work with

เราจะมาสร้าง website สำหรับเก็บ code snippets เพิ่ม code ใน `snippets/models.py`

```python
from django.db import models
from pygments.lexers import get_all_lexers
from pygments.styles import get_all_styles

LEXERS = [item for item in get_all_lexers() if item[1]]
LANGUAGE_CHOICES = sorted([(item[1][0], item[0]) for item in LEXERS])
STYLE_CHOICES = sorted([(item, item) for item in get_all_styles()])


class Snippet(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    title = models.CharField(max_length=100, blank=True, default='')
    code = models.TextField()
    linenos = models.IntegerField(default=0)
    language = models.CharField(choices=LANGUAGE_CHOICES, default='python', max_length=100)
    style = models.CharField(choices=STYLE_CHOICES, default='friendly', max_length=100)

    class Meta:
        ordering = ['created']
```

จากนั้นทำการ `makemigrations` และ `migrate`

### Creating a Serializer class

Serializer class นั้นจะมีหน้าที่ในการ serialize (แปลงข้อมูล model เป็น data type ของ Python) และ deserialize (แปลงจาก JSON มาเป็น Python dictionary)

Serializer class นั้นทำงานคล้ายกับ class Form ใน Django มากๆ

เรามาสร้างไฟล์ `snippets/serializers.py` และนำ code นี้ไปใส่

```python
from rest_framework import serializers
from snippets.models import Snippet, LANGUAGE_CHOICES, STYLE_CHOICES


class SnippetSerializer(serializers.Serializer):
    id = serializers.IntegerField(read_only=True)
    title = serializers.CharField(required=False, allow_blank=True, max_length=100)
    code = serializers.CharField()
    linenos = serializers.IntegerField(required=False)
    language = serializers.ChoiceField(choices=LANGUAGE_CHOICES, default='python')
    style = serializers.ChoiceField(choices=STYLE_CHOICES, default='friendly')

    def create(self, validated_data):
        """
        Create and return a new `Snippet` instance, given the validated data.
        """
        return Snippet.objects.create(**validated_data)

    def update(self, instance, validated_data):
        """
        Update and return an existing `Snippet` instance, given the validated data.
        """
        instance.title = validated_data.get('title', instance.title)
        instance.code = validated_data.get('code', instance.code)
        instance.linenos = validated_data.get('linenos', instance.linenos)
        instance.language = validated_data.get('language', instance.language)
        instance.style = validated_data.get('style', instance.style)
        instance.save()
        return instance
```

โดยใน serializer เราสามารถทำการ validate ข้อมูลได้ (คล้ายๆ กับ Form ใน Django เลย!)

โดยสามารถ validate ในระดับ field และ ระดับทั้ง serializer ดังตัวอย่าง

```python
...
class SnippetSerializer(serializers.Serializer):
    ...

    # Field-level validation
    def validate_linenos(self, value):
        """
        Check that line number cannot be negative.
        """
        if value and value < 0:
            raise serializers.ValidationError("Line number cannot be negative")
        return value
    
    # Serializer-level validation
    def validate(self, data):
        """
        Check that if the language is Python the snippet's title must contains 'django'
        """
        if data['language'] == 'python' and 'django' not in data['title'].lower():
            raise serializers.ValidationError("For Python, snippets must be about Django")
        return data
```

## Working with Serializers

เรามาเข้า Django shell เพื่อทดสอบการใช้งาน serializer ที่เพิ่งสร้างมาดูกัน

```sh
python manage.py shell
```

เรามาสร้างข้อมูล snippet กันก่อน

```python
from snippets.models import Snippet
from snippets.serializers import SnippetSerializer
from rest_framework.renderers import JSONRenderer
from rest_framework.parsers import JSONParser

snippet = Snippet(title='My code', code='foo = "bar"\n')
snippet.save()

snippet = Snippet(title='Hello', code='print("hello, world")\n')
snippet.save()
```

เมื่อทำการ serialize ข้อมูลตัว serializer จะทำการแปลง instance ของ model มาเป็น dictionary

```python
serializer = SnippetSerializer(snippet)
serializer.data
# {'id': 2, 'title': 'Hello', 'code': 'print("hello, world")\n', 'linenos': 0, 'language': 'python', 'style': 'friendly'}
```

จากนั้นถ้าเราต้องการแปลงเป็น `json` เราจะใช้ `JSONRenderer()`

```python
content = JSONRenderer().render(serializer.data)
content
# b'{"id":2,"title":"Hello","code":"print(\\"hello, world\\")\\n","linenos":0,"language":"python","style":"friendly"}'
```

การทำ deserialization นั้นคือการแปลงจาก `json` กลับมาเป็น Python native datatypes

```
import io

stream = io.BytesIO(content)
data = JSONParser().parse(stream)
# {'id': 2, 'title': 'Hello', 'code': 'print("hello, world")\n', 'linenos': 0, 'language': 'python', 'style': 'friendly'}
```

จากนั้นเราเอาข้อมูลที่ถูก deserialized แล้ว ใส่เข้าไปใน SnippetSerializer

```python
serializer = SnippetSerializer(data=data)
serializer.is_valid()
# False
serializer.errors
# {'non_field_errors': [ErrorDetail(string='For Python, snippets must be about Django', code='invalid')]}
```

เรามาแก้ไขให้ title ถูกต้องกัน

```python
data['title'] = 'Hello Django'
serializer = SnippetSerializer(data=data)
serializer.is_valid()
serializer.validated_data
# {'title': 'Hello Django', 'code': 'print("hello, world")', 'linenos': 0, 'language': 'python', 'style': 'friendly'}
serializer.save()
# <Snippet: Snippet object>
```

ในกรณีที่เราต้องการ serialize ข้อมูลหลายๆ instance จะใช้ attribute `many=True`

```python
serializer = SnippetSerializer(Snippet.objects.all(), many=True)
serializer.data
# [{'id': 1, 'title': 'My code', 'code': 'foo = "bar"\n', 'linenos': 0, 'language': 'python', 'style': 'friendly'}, {'id': 2, 'title': 'Hello', 'code': 'print("hello, world")\n', 'linenos': 0, 'language': 'python', 'style': 'friendly'}, {'id': 3, 'title': 'Hello Django', 'code': 'print("hello, world")', 'linenos': 0, 'language': 'python', 'style': 'friendly'}]
```

## Using ModelSerializers

เราสามารถทำให้ `SnippetSerializer` ล้อมาจาก model `Snippet` ได้โดยใช้ `ModelSerializer` คล้ายๆ กับ `Form` vs. `ModelForm` 

ลองมากแก้ไข `SnippetSerializer` กัน

```python
class SnippetSerializer(serializers.ModelSerializer):
    class Meta:
        model = Snippet
        fields = ['id', 'title', 'code', 'linenos', 'language', 'style']
```

สิ่งที่ `ModelSerializer` ทำจะมี 2 เรื่องหลักๆ ได้แก่

- สร้าง fields ให้อัตโนมัติ โดยไปล้อมาจาก model
- ทำการ implement `create()` และ `update()`

## Writing regular Django views using our Serializer

ทีนี้เราจะมาสร้าง API views เพื่อรอรับ API request

เพิ่ม code ด้่านล่างลงใน `snippets/views.py`

```python
from django.http import HttpResponse, JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.parsers import JSONParser
from snippets.models import Snippet
from snippets.serializers import SnippetSerializer

@csrf_exempt # เนื่องจากเราจะใช้ POSTMAN ยิง API มาจะไม่ได้เป็นการ submit form ดังนั้นจะไม่มี csrf token แนบมาด้วย
def snippet_list(request):
    """
    List all code snippets, or create a new snippet.
    """
    if request.method == 'GET':
        snippets = Snippet.objects.all()
        serializer = SnippetSerializer(snippets, many=True)
        return JsonResponse(serializer.data, safe=False)

    elif request.method == 'POST':
        data = JSONParser().parse(request)
        serializer = SnippetSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data, status=201)
        return JsonResponse(serializer.errors, status=400)
```

และเพิ่ม view สำหรับดูรายละเอียดของ snippet ดังนั้นเพิ่ม code ด้านล่างใน `snippets/views.py`

```python
...

@csrf_exempt
def snippet_detail(request, pk):
    """
    Retrieve, update or delete a code snippet.
    """
    try:
        snippet = Snippet.objects.get(pk=pk)
    except Snippet.DoesNotExist:
        return HttpResponse(status=404)

    if request.method == 'GET':
        serializer = SnippetSerializer(snippet)
        return JsonResponse(serializer.data)

    elif request.method == 'PUT':
        data = JSONParser().parse(request)
        serializer = SnippetSerializer(snippet, data=data)
        if serializer.is_valid():
            serializer.save()
            return JsonResponse(serializer.data)
        return JsonResponse(serializer.errors, status=400)

    elif request.method == 'DELETE':
        snippet.delete()
        return HttpResponse(status=204)
```

เพิ่ม path ใน `snippets/urls.py`

```python
from django.urls import path
from snippets import views

urlpatterns = [
    path('snippets/', views.snippet_list),
    path('snippets/<int:pk>/', views.snippet_detail),
]
```

แก้ไขไฟล์ `week13_tutorial/urls.py`

```python
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),
    path('', include('snippets.urls')),
]
```

ทดสอบการใช้งาน API ด้วย POSTMAN App

## Serializer relations

[Doc](https://www.django-rest-framework.org/api-guide/relations/#serializer-relations)

ในกรณีที่ model มีการกำหนดความสัมพันธ์เช่น one-to-one, one-to-many และ many-to-many เราสามารถใช้ `Serializer` ในการ serialize ข้อมูลที่มี relationship กันอยู่ออกมาได้เช่น 

สมมติเรามี model `Album` และ `Track` สังเกตว่า `Track` มี FK ไปหา `Album` ดังนั้นทั้ง 2 models นี้มีความสัมพันธ์กันแบบ one-to-many

```python
class Album(models.Model):
    album_name = models.CharField(max_length=100)
    artist = models.CharField(max_length=100)

class Track(models.Model):
    album = models.ForeignKey(Album, related_name='tracks', on_delete=models.CASCADE)
    order = models.IntegerField()
    title = models.CharField(max_length=100)
    duration = models.IntegerField()

    class Meta:
        unique_together = ['album', 'order']
        ordering = ['order']

    def __str__(self):
        return '%d: %s' % (self.order, self.title)
```

### StringRelatedField

จะแสดงผลข้อมูล `__str__` method ดังตัวอย่าง

```python
class AlbumSerializer(serializers.ModelSerializer):
    tracks = serializers.StringRelatedField(many=True)

    class Meta:
        model = Album
        fields = ['album_name', 'artist', 'tracks']
```

ผลที่ได้จาก `serializer.data` จะเป็นดังนี้

```python
{
    'album_name': 'Things We Lost In The Fire',
    'artist': 'Low',
    'tracks': [
        '1: Sunflower',
        '2: Whitetail',
        '3: Dinosaur Act',
        ...
    ]
}
```

### PrimaryKeyRelatedField

จะแสดงข้อมูล primary key ของตารางที่เกี่ยวข้อง

```python
class AlbumSerializer(serializers.ModelSerializer):
    tracks = serializers.PrimaryKeyRelatedField(many=True, read_only=True)

    class Meta:
        model = Album
        fields = ['album_name', 'artist', 'tracks']
```

ผลที่ได้จาก `serializer.data` จะเป็นดังนี้

```python
{
    'album_name': 'Things We Lost In The Fire',
    'artist': 'Low',
    'tracks': [
        89,
        90,
        91,
        ...
    ]
}
```

### Nested relationships

ในกรณีที่เราจ้องการแสดงข้อมูลที่เกี่ยวข้องเป็น list of objects เป็น nested ลงไปเราสามารถทำได้โดยการประกาศ `Serialier` ของ object ที่เกี่ยวข้องนั้นๆ และนำมาเรียกใช้เป็น field ดังตัวอย่าง

**Note:** ในกรณีที่เราอยู่ในฝั่ง one สำหรับ one-to-many จะต้องใช้ `many=True` นะครับ

```python
class TrackSerializer(serializers.ModelSerializer):
    class Meta:
        model = Track
        fields = ['order', 'title', 'duration']

class AlbumSerializer(serializers.ModelSerializer):
    tracks = TrackSerializer(many=True, read_only=True)

    class Meta:
        model = Album
        fields = ['album_name', 'artist', 'tracks']
```

โดย `AlbumSerializer` จะแสดงผลดังนี้

```python
>>> album = Album.objects.create(album_name="The Grey Album", artist='Danger Mouse')
>>> Track.objects.create(album=album, order=1, title='Public Service Announcement', duration=245)
<Track: Track object>
>>> Track.objects.create(album=album, order=2, title='What More Can I Say', duration=264)
<Track: Track object>
>>> Track.objects.create(album=album, order=3, title='Encore', duration=159)
<Track: Track object>
>>> serializer = AlbumSerializer(instance=album)
>>> serializer.data
{
    'album_name': 'The Grey Album',
    'artist': 'Danger Mouse',
    'tracks': [
        {'order': 1, 'title': 'Public Service Announcement', 'duration': 245},
        {'order': 2, 'title': 'What More Can I Say', 'duration': 264},
        {'order': 3, 'title': 'Encore', 'duration': 159},
    ],
}
```

#### เรามาลองทำ tutorial ของเรากันต่อ

ทำการเพิ่ม model `SnippetCategory` เข้าไป และเพิ่ม FK ไปใน model `Snippet` ดังนี้

```python
# snippets/models.py
...
class SnippetCategory(models.Model):
    name = models.CharField(max_length=100)


class Snippet(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    title = models.CharField(max_length=100, blank=True, default='')
    code = models.TextField()
    linenos = models.IntegerField(default=0)
    language = models.CharField(choices=LANGUAGE_CHOICES, default='python', max_length=100)
    style = models.CharField(choices=STYLE_CHOICES, default='friendly', max_length=100)
    category = models.ForeignKey(SnippetCategory, null=True, on_delete=models.CASCADE)

    class Meta:
        ordering = ['created']
```

ทำการเพิ่ม `SnippetCategorySerializer` ไปใน `snippets/serialziers.py`

```python
from rest_framework import serializers
from snippets.models import Snippet, SnippetCategory

class SnippetCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = SnippetCategory
        fields = ['id', 'name']

class SnippetSerializer(serializers.ModelSerializer):
    category = SnippetCategorySerializer()

    class Meta:
        model = Snippet
        fields = ['id', 'title', 'code', 'linenos', 'language', 'style', 'category']
```

ทดสอบการใช้งาน API ด้วย POSTMAN App

#### มาลองใช้งาน many=True กัน

ปรับเพิ่มข้อมูลของ Snippet ที่เกี่ยวข้องใน `SnippetCategorySerializer` ดังนี้

```python
from rest_framework import serializers
from snippets.models import Snippet, SnippetCategory

class SnippetSerializer(serializers.ModelSerializer):
    category = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = Snippet
        fields = ['id', 'title', 'code', 'linenos', 'language', 'style', 'category']

class SnippetCategorySerializer(serializers.ModelSerializer):
    snippet_set = SnippetSerializer(many=True, read_only=True)

    class Meta:
        model = SnippetCategory
        fields = ['id', 'name', 'snippet_set']
```

เพิ่ม path และ view สำหรับ GET list ของ `SnippetCategory`

```python
# snippets/urls
from django.urls import path
from snippets import views

urlpatterns = [
    path('snippets/', views.snippet_list),
    path('snippets/<int:pk>/', views.snippet_detail),
    path('categories/', views.category_list),
]
```

และ เพิ่ม view ใน `snippets/views.py`

```python
...
from snippets.models import Snippet, SnippetCategory
from snippets.serializers import SnippetSerializer, SnippetCategorySerializer
...
def category_list(request):
    """
    List all snippet categories.
    """
    if request.method == 'GET':
        categories = SnippetCategory.objects.all()
        serializer = SnippetCategorySerializer(categories, many=True)
        return JsonResponse(serializer.data, safe=False)
```

ทดสอบการใช้งาน API ด้วย POSTMAN App
