import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_credit_card/credit_card_widget.dart';

import 'package:stripe_app/bloc/pagar/pagar_bloc.dart';
import 'package:stripe_app/data/tarjetas.dart';
import 'package:stripe_app/helpers/helpers.dart';
import 'package:stripe_app/pages/tarjeta_page.dart';
import 'package:stripe_app/services/stripe_service.dart';
import 'package:stripe_app/widgets/total_pay_button.dart';

class HomePage extends StatelessWidget {
  final stripeService = StripeService();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final pagarBloc = context.read<PagarBloc>();
    return Scaffold(
        appBar: AppBar(
          leading: const Text(''),
          title: const Text('Pagar'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                mostrarLoading(context);
                final amount = pagarBloc.state.montoPagarString;
                final currency = pagarBloc.state.moneda;
                final resp = await stripeService.pagarNuevaTarjeta(
                    amount: amount, currency: currency);
                Navigator.pop(context);
                if (resp.ok) {
                  mostrarAlerta(context, 'Tarjeta Ok', 'Pago correcto');
                } else {
                  mostrarAlerta(context, 'Algo salio mal', '${resp.msg}');
                }
              },
            )
          ],
        ),
        body: Stack(
          children: [
            Positioned(
              width: size.width,
              height: size.height,
              top: 150,
              child: PageView.builder(
                  controller: PageController(viewportFraction: 0.9),
                  itemCount: tarjetas.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (_, i) {
                    final tarjeta = tarjetas[i];
                    return GestureDetector(
                      onTap: () {
                        BlocProvider.of<PagarBloc>(context)
                            .add(OnSeleccionarTarjeta(tarjeta));
                        Navigator.push(
                            context, navegarFadeIn(context, TarjetaPage()));
                      },
                      child: Hero(
                        tag: tarjeta.cardNumber,
                        child: CreditCardWidget(
                          cardNumber: tarjeta.cardNumberHidden,
                          expiryDate: tarjeta.expiracyDate,
                          cardHolderName: tarjeta.cardHolderName,
                          cvvCode: tarjeta.cvv,
                          showBackView: false,
                          onCreditCardWidgetChange: (_) {},
                        ),
                      ),
                    );
                  }),
            ),
            Positioned(bottom: 0, child: TotalPayButton()),
          ],
        ));
  }
}
