INSERT INTO appointments_doctor (name, specialization, email, phone_number) VALUES
('John Smith', 'Cardiology', 'johnsmith@example.com', '1234567890'),
('Emily Johnson', 'Pediatrics', 'emilyjohnson@example.com', '1234567891'),
('Michael Brown', 'Orthopedics', 'michaelbrown@example.com', '1234567892'),
('Jessica Davis', 'Neurology', 'jessicadavis@example.com', '1234567893'),
('David Wilson', 'Dermatology', 'davidwilson@example.com', '1234567894');

INSERT INTO appointments_patient (name, email, phone_number, address) VALUES
('Alice', 'alice@example.com', '0987654321', '123 Main St, City'),
('Bob', 'bob@example.com', '0987654322', '456 Elm St, City'),
('Charlie', 'charlie@example.com', '0987654323', '789 Oak St, City'),
('Diana', 'diana@example.com', '0987654324', '101 Pine St, City'),
('Ethan', 'ethan@example.com', '0987654325', '202 Maple St, City'),
('Fiona', 'fiona@example.com', '0987654326', '303 Birch St, City'),
('George', 'george@example.com', '0987654327', '404 Cedar St, City');


INSERT INTO appointments_appointment (doctor_id, patient_id, date, at_time, details) VALUES
(1, 1, '2024-09-28', '10:00:00', 'Initial consultation for heart health'),
(1, 2, '2024-09-28', '11:00:00', 'Follow-up visit for check-up');