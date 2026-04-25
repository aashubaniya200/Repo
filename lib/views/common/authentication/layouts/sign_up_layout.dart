import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:webpal_commerce/config/app_color.dart';
import 'package:webpal_commerce/config/app_constants.dart';
import 'package:webpal_commerce/config/app_text_style.dart';
import 'package:webpal_commerce/config/theme.dart';
import 'package:webpal_commerce/controllers/common/master_controller.dart';
import 'package:webpal_commerce/controllers/eCommerce/authentication/authentication_controller.dart';
import 'package:webpal_commerce/controllers/misc/misc_controller.dart';
import 'package:webpal_commerce/models/common/all_country_model/country.dart';
import 'package:webpal_commerce/models/eCommerce/authentication/sign_up.dart';
import 'package:webpal_commerce/routes.dart';
import 'package:webpal_commerce/utils/context_less_navigation.dart';
import 'package:webpal_commerce/utils/global_function.dart';
import 'package:webpal_commerce/views/common/authentication/layouts/confirm_otp_layout.dart';

class SignUpLayout extends StatefulWidget {
  const SignUpLayout({super.key});

  @override
  State<SignUpLayout> createState() => _SignUpLayoutState();
}

class _SignUpLayoutState extends State<SignUpLayout> {
  final List<TextEditingController> controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );

  final List<FocusNode> fNodes = List.generate(4, (i) => FocusNode());

  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  bool isChecked = false;
  Country? selectedCountry;
  String? countryCode;

  @override
  void initState() {
    super.initState();
    selectedCountry = Country(
      id: 149,
      name: 'Nepal',
      phoneCode: '+977',
    );
    countryCode = '+977';
  }

  @override
  void dispose() {
    for (var element in controllers) {
      element.dispose();
    }
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
                    Gap(32.h),
                    // Title
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Register',
                            textAlign: TextAlign.center,
                            style: AppTextStyle(context).title.copyWith(
                              fontSize: 32.sp,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          Gap(8.h),
                          Text(
                            'Join us and start your shopping journey!',
                            textAlign: TextAlign.center,
                            style: AppTextStyle(context).bodyText.copyWith(
                              color: colors(context).bodyTextSmallColor,
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Gap(32.h),
                    // Form Fields
                    _buildTextField(
                      context: context,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      controller: controllers[0],
                      focusNode: fNodes[0],
                      keyboardType: TextInputType.name,
                      prefixIcon: Icons.person_outline,
                      validator: (value) => GlobalFunction.commonValidator(
                        value: value!,
                        hintText: 'Full Name',
                        context: context,
                      ),
                    ),
                    Gap(16.h),
                    _buildPhoneField(context),
                    Gap(16.h),
                    _buildTextField(
                      context: context,
                      label: 'Email Address',
                      hint: 'Enter your email',
                      controller: controllers[2],
                      focusNode: fNodes[2],
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) => GlobalFunction.emailValidator(
                        value: value!,
                        hintText: 'Email',
                        context: context,
                      ),
                    ),
                    Gap(16.h),
                    Consumer(builder: (context, ref, _) {
                      return _buildTextField(
                        context: context,
                        label: 'Password',
                        hint: 'Create a password',
                        controller: controllers[3],
                        focusNode: fNodes[3],
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
                    Gap(20.h),
                    // Terms & Conditions
                    _buildTermsCheckbox(context),
                    Gap(32.h),
                    // Sign Up Button
                    Consumer(builder: (context, ref, _) {
                      return _buildPrimaryButton(
                        context: context,
                        text: 'Sign Up',
                        isLoading: ref.watch(authControllerProvider),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          if (formKey.currentState!.validate()) {
                            final SingUp singUpInfo = SingUp(
                              name: controllers[0].text,
                              phone: controllers[1].text,
                              password: controllers[3].text,
                              country: selectedCountry?.name ?? "",
                              phoneCode: countryCode ?? '',
                              email: controllers[2].text,
                            );
                            if (isChecked) {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .singUp(singUpInfo: singUpInfo)
                                  .then((response) {
                                if (response.isSuccess) {
                                  _navigate(ref: ref);
                                } else {
                                  GlobalFunction.showCustomSnackbar(
                                    message: response.message,
                                    isSuccess: false,
                                  );
                                }
                              });
                            } else {
                              GlobalFunction.showCustomSnackbar(
                                message:
                                    'Please accept the terms and conditions!',
                                isSuccess: false,
                              );
                            }
                          }
                        },
                      );
                    }),
                    Gap(24.h),
                  ],
                ),
              ),
            ),
          ),
        ),
          // Login Link - Sticky at bottom
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: AppTextStyle(context).bodyText.copyWith(
                    color: colors(context).bodyTextSmallColor,
                  ),
                ),
                TextButton(
                  onPressed: () => context.nav.pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Login',
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

  Widget _buildPhoneField(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final materModelData =
          ref.watch(masterControllerProvider.notifier).materModel.data;
      final isPhoneRequired = materModelData.phoneRequired;
      int? phoneMinLength = materModelData.phoneMinLength;
      int? phoneMaxLength = materModelData.phoneMaxLength;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phone Number',
            style: AppTextStyle(context).bodyText.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          Gap(8.h),
          Row(
            children: [
              Container(
                width: 80.w,
                height: 56.h,
                decoration: BoxDecoration(
                  color: colors(context).accentColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: colors(context).accentColor!,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    countryCode ?? '+977',
                    style: AppTextStyle(context).bodyText.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Gap(12.w),
              Expanded(
                child: TextFormField(
                  controller: controllers[1],
                  focusNode: fNodes[1],
                  keyboardType: TextInputType.phone,
                  style: AppTextStyle(context).bodyText,
                  validator: (value) => GlobalFunction.phoneValidator(
                    value: value!,
                    hintText: 'Phone Number',
                    context: context,
                    minLength: phoneMinLength,
                    maxLength: phoneMaxLength,
                    isPhoneRequired: isPhoneRequired,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: AppTextStyle(context).bodyText.copyWith(
                      color: colors(context).hintTextColor,
                    ),
                    prefixIcon: Icon(
                      Icons.phone_outlined,
                      color: colors(context).primaryColor,
                      size: 22.sp,
                    ),
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
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24.h,
          width: 24.w,
          child: Checkbox(
            value: isChecked,
            onChanged: (value) {
              setState(() {
                isChecked = value!;
              });
            },
            activeColor: colors(context).primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.r),
            ),
          ),
        ),
        Gap(12.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'I agree to the ',
                  style: AppTextStyle(context).bodyText.copyWith(
                    fontSize: 14.sp,
                    color: colors(context).bodyTextColor,
                  ),
                ),
                TextSpan(
                  text: 'Terms & Conditions',
                  style: AppTextStyle(context).bodyText.copyWith(
                    fontSize: 14.sp,
                    color: colors(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => context.nav
                        .pushNamed(Routes.termsAndConditionsView),
                ),
                TextSpan(
                  text: ' and ',
                  style: AppTextStyle(context).bodyText.copyWith(
                    fontSize: 14.sp,
                    color: colors(context).bodyTextColor,
                  ),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: AppTextStyle(context).bodyText.copyWith(
                    fontSize: 14.sp,
                    color: colors(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () =>
                        context.nav.pushNamed(Routes.privacyPolicyView),
                ),
              ],
            ),
          ),
        ),
      ],
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

  void _navigate({required WidgetRef ref}) {
    if (ref
            .read(masterControllerProvider.notifier)
            .materModel
            .data
            .registerOtpVerify ==
        true) {
      if (context.mounted) {
        // Get the OTP type (phone or email)
        final registerOtpType = ref
            .read(masterControllerProvider.notifier)
            .materModel
            .data
            .registerOtpType;
        
        // Use phone or email based on OTP type
        final otpContact = registerOtpType == 'email' 
            ? controllers[2].text  // email is at index 2
            : controllers[1].text; // phone is at index 1
        
        // Navigate directly to confirm OTP with the contact info
        context.nav.pushNamed(
          Routes.confirmOTP,
          arguments: ConfirmOTPScreenArguments(
            phoneNumber: otpContact,
            isPasswordRecover: false,
          ),
        );
      }
    } else {
      if (context.mounted) {
        context.nav.pushNamedAndRemoveUntil(
          Routes.getCoreRouteName(AppConstants.appServiceName),
          (route) => false,
        );
      }
    }
  }
}
