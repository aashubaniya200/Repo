import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/eCommerce/address/address_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/authentication/authentication_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/services/common/hive_service_provider.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';

class LoginLayout extends StatefulWidget {
  const LoginLayout({super.key});

  @override
  State<LoginLayout> createState() => _LoginLayoutState();
}

class _LoginLayoutState extends State<LoginLayout> {
  final TextEditingController phoneController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final List<FocusNode> fNodes = [FocusNode(), FocusNode()];

  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).scaffoldBackgroundColor == EcommerceAppColor.black;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDark ? EcommerceAppColor.black : Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: FormBuilder(
                    key: formKey,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Gap(40.h),
                    // App Logo
                    Center(
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: colors(context).primaryColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Image.asset(
                          'assets/png/ic_launcher_round.png',
                          width: 80.w,
                          height: 80.w,
                        ),
                      ),
                    ),
                    Gap(40.h),
                    // Welcome Text
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: AppTextStyle(context).title.copyWith(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          Gap(8.h),
                          Text(
                            'Please login to your account',
                            textAlign: TextAlign.center,
                            style: AppTextStyle(context).bodyText.copyWith(
                              color: colors(context).bodyTextSmallColor,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(40.h),
                    // Email/Phone Field
                    _buildTextField(
                      context: context,
                      label: 'Email or Phone',
                      hint: 'Enter your email or phone number',
                      controller: phoneController,
                      focusNode: fNodes[0],
                      keyboardType: TextInputType.text,
                      prefixIcon: Icons.person_outline,
                      validator: (value) => GlobalFunction.commonValidator(
                        value: value!,
                        hintText: 'Email or Phone',
                        context: context,
                      ),
                    ),
                    Gap(20.h),
                    // Password Field
                    Consumer(builder: (context, ref, _) {
                      return _buildTextField(
                        context: context,
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: passwordController,
                        focusNode: fNodes[1],
                        keyboardType: TextInputType.visiblePassword,
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: ref.watch(obscureText1),
                        onTogglePassword: () {
                          ref.read(obscureText1.notifier).state =
                              !ref.read(obscureText1);
                        },
                        validator: (value) => GlobalFunction.passwordValidator(
                          value: value!,
                          hintText: 'Password',
                          context: context,
                        ),
                      );
                    }),
                    Gap(16.h),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.nav.pushNamed(
                          Routes.recoverPassword,
                          arguments: true,
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyle(context).bodyText.copyWith(
                            color: colors(context).primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Gap(32.h),
                    // Login Button
                    Consumer(builder: (context, ref, _) {
                      return _buildPrimaryButton(
                        context: context,
                        text: 'Login',
                        isLoading: ref.watch(authControllerProvider),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (formKey.currentState!.validate()) {
                            ref
                                .read(authControllerProvider.notifier)
                                .login(
                                  phone: phoneController.text,
                                  password: passwordController.text,
                                )
                                .then((response) {
                              ref
                                  .read(addressControllerProvider.notifier)
                                  .getAddress();
                              if (response.isSuccess) {
                                context.nav.pushNamed(Routes.getCoreRouteName(
                                    AppConstants.appServiceName));
                              }
                            });
                          }
                        },
                      );
                    }),
                    Gap(16.h),
                    // Skip Button
                    Consumer(
                      builder: (context, ref, _) {
                        return Visibility(
                          visible: !ref.read(hiveServiceProvider).userIsLoggedIn(),
                          child: _buildOutlinedButton(
                            context: context,
                            text: 'Skip for now',
                            onPressed: () {
                              context.nav.pushNamed(
                                Routes.getCoreRouteName(AppConstants.appServiceName),
                              );
                            },
                          ),
                        );
                      },
                    ),
                    Gap(24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
          // Sign Up Link - Sticky at bottom
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an account? ',
                  style: AppTextStyle(context).bodyText.copyWith(
                    color: colors(context).bodyTextSmallColor,
                  ),
                ),
                TextButton(
                  onPressed: () => context.nav.pushNamed(Routes.singUp),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Sign Up',
                    style: AppTextStyle(context).bodyText.copyWith(
                      color: colors(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required TextInputType keyboardType,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyle(context).bodyText.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
          ),
        ),
        Gap(8.h),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: AppTextStyle(context).bodyText,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyle(context).bodyText.copyWith(
              color: colors(context).hintTextColor,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: colors(context).primaryColor,
              size: 22.sp,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    onPressed: onTogglePassword,
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: colors(context).hintTextColor,
                      size: 22.sp,
                    ),
                  )
                : null,
            filled: true,
            fillColor: colors(context).accentColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: colors(context).accentColor!,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: colors(context).primaryColor!,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(
                color: colors(context).errorColor!,
                width: 1,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          disabledBackgroundColor: colors(context).primaryColor!.withOpacity(0.6),
        ),
        child: isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.w,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: AppTextStyle(context).buttonText.copyWith(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors(context).primaryColor,
          side: BorderSide(
            color: colors(context).primaryColor!,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          text,
          style: AppTextStyle(context).buttonText.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: colors(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
