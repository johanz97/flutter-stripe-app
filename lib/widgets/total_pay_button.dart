import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:stripe_app/bloc/pagar/pagar_bloc.dart';
import 'package:stripe_app/helpers/helpers.dart';
import 'package:stripe_app/services/stripe_service.dart';
import 'package:stripe_payment/stripe_payment.dart';

class TotalPayButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final pagarBloc = context.read<PagarBloc>().state;
    return Container(
        width: width,
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30), topRight: Radius.circular(30))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text('${pagarBloc.montoPagar} ${pagarBloc.moneda}',
                    style: const TextStyle(fontSize: 20))
              ],
            ),
            BlocBuilder<PagarBloc, PagarState>(
              builder: (BuildContext context, state) {
                return _BtnPay(state.tarjetaActiva);
              },
            )
          ],
        ));
  }
}

class _BtnPay extends StatelessWidget {
  final bool tipoPago;

  const _BtnPay(this.tipoPago);

  @override
  Widget build(BuildContext context) {
    return tipoPago
        ? buildBotonTarjeta(context)
        : buildAppleAndGooglePlay(context);
  }

  Widget buildBotonTarjeta(BuildContext context) {
    return MaterialButton(
      height: 45,
      minWidth: 170,
      shape: const StadiumBorder(),
      elevation: 0,
      color: Colors.black,
      child: Row(
        children: const [
          Icon(
            FontAwesomeIcons.solidCreditCard,
            color: Colors.white,
          ),
          Text(
            ' Pagar',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ],
      ),
      onPressed: () async {
        mostrarLoading(context);
        final stripeService = StripeService();
        final pagarState = context.read<PagarBloc>().state;
        final tarjeta = pagarState.tarjeta;
        final mesAnio = tarjeta!.expiracyDate.split('/');

        final resp = await stripeService.pagarTarjetaExistente(
            amount: pagarState.montoPagarString,
            currency: pagarState.moneda,
            card: CreditCard(
                number: tarjeta.cardNumber,
                expMonth: int.parse(mesAnio[0]),
                expYear: int.parse(mesAnio[1])));
        Navigator.pop(context);
        if (resp.ok) {
          mostrarAlerta(context, 'Tarjeta Ok', 'Pago correcto');
        } else {
          mostrarAlerta(context, 'Algo salio mal', '${resp.msg}');
        }
      },
    );
  }

  Widget buildAppleAndGooglePlay(BuildContext context) {
    return MaterialButton(
      height: 45,
      minWidth: 150,
      shape: const StadiumBorder(),
      elevation: 0,
      color: Colors.black,
      child: Row(
        children: [
          Icon(
            Platform.isAndroid
                ? FontAwesomeIcons.google
                : FontAwesomeIcons.apple,
            color: Colors.white,
          ),
          const Text(
            ' Pay',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
        ],
      ),
      onPressed: () {
        final stripeService = StripeService();
        final pagarState = context.read<PagarBloc>().state;
        stripeService.pagarGoogleApple(
            amount: pagarState.montoPagarString, currency: pagarState.moneda);
      },
    );
  }
}
