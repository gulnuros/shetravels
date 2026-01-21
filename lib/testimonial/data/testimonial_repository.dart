
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shetravels/testimonial/data/model/testimonial.dart';


class TestimonialRepository {
  static final CollectionReference testimonialsRef =
      FirebaseFirestore.instance.collection('testimonials');

  static Future<void> addTestimonial(Testimonial t) {
    return testimonialsRef.add(t.toMap());
  }

  static Future<void> removeTestimonial(String id) {
    return testimonialsRef.doc(id).delete();
  }

  static Stream<List<Testimonial>> getTestimonialsStream() {
    return testimonialsRef.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Testimonial.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList());
  }
}
