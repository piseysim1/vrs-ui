part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const Register = _Paths.Register;
}

abstract class _Paths {
  _Paths._();
  static const Register = '/register';
  static const Login = '/login';
  static const Home = '/home';
  static const VehicleDetail = '/vehicle/:id';
  static const Admin = '/admin';
  static const Checkout = '/checkout/:id';
}
