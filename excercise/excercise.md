# Excercise WEEK 13

แอปนัดหมายกับหมอมี API หลัก ๆ ที่ใช้ในการจัดการข้อมูลแพทย์ ผู้ป่วย และนัดหมาย โดยแต่ละ API จะมีเส้นทาง (URL) และฟังก์ชันการทำงานที่แตกต่างกันไป ดังนี้:

**API endpoints**

    - GET /api/doctors/

    - GET /api/patients/

    - GET /api/appointments/ 

    - GET /api/appointments/<id>/

    - POST /api/appointments/

    - PUT,PATCH /api/appointments/<id>/

    - DELETE /api/appointments/<id>/

## คำสั่ง

1. ให้นักศึกษาสร้างโปรเจคชื่อ `doctor_appointment`
2. start app ชื่อ `appointments`
3. แก้ไขไฟล์ models.py ใน `appointments/models.py`

```PYTHON
class Doctor(models.Model):
    name = models.CharField(max_length=150)
    specialization = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=15, unique=True)

    def __str__(self):
        return f'Dr. {self.name} ({self.specialization})'


class Patient(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField(null=True)
    phone_number = models.CharField(max_length=15)
    address = models.TextField()

    def __str__(self):
        return self.name


class Appointment(models.Model):
    doctor = models.ForeignKey(Doctor, on_delete=models.CASCADE)
    patient = models.ForeignKey(Patient, on_delete=models.CASCADE)
    date = models.DateField()
    at_time = models.TimeField()
    details = models.TextField(null=True, blank=True)

    def __str__(self):
        return f'Appointment with Dr. {self.doctor.name} for {self.patient.name} on {self.date.strftime("YYYY-MM-DD HH:mm")}'

```

4. สร้าง database ชื่อ `doctor_app_db` และแก้ไข `settings.py`

แก้ไข INSTALLED_APPS

```PYTHON
    INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'appointments'
]
```

แก้ไข DATABASES

```
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": "doctor_app_db",
        "USER":  "ชื่อผู้ใช้",
        "PASSWORD": "รหัสผ่าน",
        "HOST": "localhost",
        "PORT": "5432",
    }
}
```

4. สั่ง makemigrations และ migrate
5. สร้างไฟล์ `appointment/serializers.py` และแก้ไข code

```PYTHON
class DoctorSerializer(serializers.ModelSerializer):
    class Meta:
        model = Doctor
        fields = [
            "id",
            "name",
            "specialization",
            "phone_number",
            "email"
        ]


class PatientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Patient
        fields = [
            "id",
            "name",
            "phone_number",
            "email",
            "address"
        ]
```

6. แก้ไขไฟล์ view.py ใน `appointments/views.py`

```PYTHON
class DoctorList(APIView):
    def get(self, request):
        doctors = Doctor.objects.all()
        serializer = DoctorSerializer(doctors, many=True)
        return Response(serializer.data)

class PatientList(APIView):
    def get(self, request):
        patients = Patient.objects.all()
        serializer = PatientSerializer(patients, many=True)
        return Response(serializer.data)

```

สร้างไฟล์ urls.py ใน appointments และแก้ไข code

```PYTHON
urlpatterns = [
    path('doctors/', DoctorList.as_view(), name='doctor-list'),
    path('patients/', PatientList.as_view(), name='patient-list'),
]
```

แก้ไขไฟล์ urls.py ใน `doctor_appointment/urls.py`

```PYTHON
urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('appointments.urls')),
]
```

7. ทำการ insert ข้อมูลในไฟล์ `doctor_app.sql`

*จะเห็นได้ว่าเรามี API สำหรับ Get ข้อมูล คุณหมอ และผู้ป่วยแล้ว* สามารทดลองยิง API ใน postman ได้เลย

- http://127.0.0.1:8000/api/doctors/
- http://127.0.0.1:8000/api/patients/

แต่เรายังไม่มี API สำหรับ Get ข้อมูล และสร้างลบแก้ไขนัดหมาย


## PART 1: Appointment list

### 1.1 GET: สร้าง API ดึงข้อมูลรายการนัดหมายทั้งหมด (GET - appointment list) (1 คะแนน)

**Hint**: ควรจะต้องมีการใช้งาน PatientSerializer และ DoctorSerializer เนื่องจากมี FK ไปยัง `Doctor` และ `Patient`

ตัวอย่าง Response ที่ต้องการ

```JSON
[
    {
        "id": 1,
        "doctor": {
            "id": 1,
            "name": "John Smith",
            "specialization": "Cardiology",
            "phone_number": "1234567890",
            "email": "johnsmith@example.com"
        },
        "patient": {
            "id": 1,
            "name": "Alice",
            "phone_number": "0987654321",
            "email": "alice@example.com",
            "address": "123 Main St, City"
        },
        "date": "2024-09-28",
        "at_time": "10:00:00",
        "details": "Initial consultation for heart health"
    },
    {
        "id": 2,
        "doctor": {
            "id": 1,
            "name": "John Smith",
            "specialization": "Cardiology",
            "phone_number": "1234567890",
            "email": "johnsmith@example.com"
        },
        "patient": {
            "id": 2,
            "name": "Bob",
            "phone_number": "0987654322",
            "email": "bob@example.com",
            "address": "456 Elm St, City"
        },
        "date": "2024-09-28",
        "at_time": "11:00:00",
        "details": "Follow-up visit for check-up"
    }
]
```

### 1.2  POST: สร้าง API สำหรับเพิ่มข้อมูล Appointment โดยให้มีการตรวจสอบ วันที่และเวลา ไม่ให้สามารถสร้างนัดหมายใน วันและเวลา ที่ผ่านไปแล้วได้ (1 คะแนน)

**Hint**: ควรจะต้องมีการ validate ข้อมูลใน `AppointmentSerializer`

ตัวอย่างข้อมูลสำหรับ ยิง API สร้างนัดหมาย

```JSON
{
    "doctor": 1,       // ID ของแพทย์ที่คุณต้องการนัดหมาย
    "patient": 2,     // ID ของผู้ป่วยที่ทำการนัดหมาย
    "date": "2024-09-30",     // วันที่นัดหมาย (ในรูปแบบ YYYY-MM-DD)
    "at_time": "10:30:00",    // เวลานัดหมาย (ในรูปแบบ HH:MM:SS)
    "details": "Follow-up appointment regarding recent test results" // รายละเอียดเพิ่มเติม
}
```


ตัวอย่าง Response เมื่อ input ข้อมูลที่ไม่ถูกต้อง

Request:

```JSON
{
    "doctor": 1,
    "patient": 1,
    "date": "2023-08-30",  // วันที่ในอดีต
    "at_time": "10:30:00",
    "details": "Follow-up appointment"
}
```

Response: (status code 400 bad request)

```JSON
{
    "non_field_errors": [
        "The appointment date or time must be in the future."
    ]
}
```

## PART 2: Appointment Detail

> หมายเหตุ: หากไม่พบ id ใน database ให้ response status code 404 Not Found

### 2.1 GET: สร้าง API ดึงข้อมูลนัดหมายจาก id (GET - appointment detail) (0.5 คะแนน)

ตัวอย่าง Response ที่ต้องการ

```JSON
{
    "id": 1,
    "doctor": {
        "id": 1,
        "name": "John Smith",
        "specialization": "Cardiology",
        "phone_number": "1234567890",
        "email": "johnsmith@example.com"
    },
    "patient": {
        "id": 1,
        "name": "Alice",
        "phone_number": "0987654321",
        "email": "alice@example.com",
        "address": "123 Main St, City"
    },
    "date": "2024-09-28",
    "at_time": "10:00:00",
    "details": "Initial consultation for heart health"
}
```

### 2.2 PUT หรือ PATCH: สร้าง API สำหรับแก้ไขข้อมูลนัดหมาย โดยให้มีการตรวจสอบ วันที่และเวลา ไม่ให้สามารถสร้างนัดหมายใน วันและเวลา ที่ผ่านไปแล้วได้ (0.5 คะแนน)

ตัวอย่างข้อมูลสำหรับ ยิง API แก้ไขข้อมูลนัดหมาย

```JSON
{
    "doctor": 1,       // ID ของแพทย์ที่คุณต้องการนัดหมาย
    "patient": 2,     // ID ของผู้ป่วยที่ทำการนัดหมาย
    "date": "2024-09-30",     // วันที่นัดหมาย (ในรูปแบบ YYYY-MM-DD)
    "at_time": "10:30:00",    // เวลานัดหมาย (ในรูปแบบ HH:MM:SS)
    "details": "Follow-up appointment regarding recent test results" // รายละเอียดเพิ่มเติม
}
```

ตัวอย่าง Response เมื่อ input ข้อมูลที่ไม่ถูกต้อง

Request:

```JSON
{
    "doctor": 1,
    "patient": 1,
    "date": "2023-07-10",  // วันที่ในอดีต
    "at_time": "10:30:00",
    "details": "Follow-up appointment"
}
```

Response: (status code 400 bad request)

```JSON
{
    "non_field_errors": [
        "The appointment date or time must be in the future."
    ]
}
```

### 2.3 DELETE: สร้าง API สำหรับ ลบข้อมูลนัดหมาย (Delete by id) (0.5 คะแนน)

Response: (status code 204 No Content)
